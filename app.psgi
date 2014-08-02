use 5.10.0;
use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.12';

use File::Copy 'copy';
use Path::Class;
use Teng::Schema::Loader;
use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;
use Hirukara;
use Hirukara::Util;
use Hirukara::Constants::Area;
use Hirukara::Constants::CircleType;
use Hirukara::ActionLog;

__PACKAGE__->template_options(
    'function' => {
        circle_space => Hirukara::Util->can('get_circle_space'),
        area_lookup  => Hirukara::Constants::Area->can('lookup'),
        circle_type_lookup  => Hirukara::Constants::CircleType->can('lookup'),
    }
);

sub loggin_user {
    my($c) = @_;
    $c->session->get("user");
}

my $db;
my $hirukara;

sub hirukara    {
    my $self = shift;
    $hirukara //= do {
        Hirukara->new(database => $self->db);
    }
}

sub db {
    my $self = shift;
    $db //= do {
        my $conf = $self->config->{Teng} or die "config Teng missing";
        my $db = Teng::Schema::Loader->load(%$conf);
        $db->load_plugin("SearchJoined");
        $db;
    };
}

sub checklist_dir   {
    my $c = shift;
    $c->{checklist_dir} //= do {
        my $dir = dir("./checklist");
        $dir->mkpath;
        $dir;
    };
}

sub render  {
    my($c,$file,$param) = @_;
    $param ||= {};
    $param->{user} = $c->session->get("user");
    $c->SUPER::render($file,$param);
}


get '/' => sub {
    my $c = shift;

    if ( !$c->session->get("user") ) {
        return $c->render("login.tt");
    }

    return $c->redirect("/view");
};

get '/mypage' => sub { my $c = shift; $c->render("mypage.tt") };

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;
    my $user = $c->session->get("user");
    my $circle = $c->hirukara->get_circle_by_id(id => $args->{circle_id})
        or return $c->create_simple_status_page(404, "Circle Not Found");

    my $it = $c->hirukara->get_checklists_by_circle_id($circle->id);
    my $my = $c->hirukara->get_checklist({ circle_id => $circle->id, member_id => $user->{member_id} });

    $c->fillin_form({
        circle_type       => $circle->circle_type,
        circle_comment    => $circle->comment,
        checklist_comment => $my ? $my->comment : "",
        order_count       => $my ? $my->count : 0,
    });

    $c->render("circle.tt", {
        circle    => $circle,
        checklist => $it,
        my        => $my,
        types     => [Hirukara::Constants::CircleType->circle_types],
        circle_type => Hirukara::Constants::CircleType::lookup($circle->circle_type),
    });
};

post '/circle/update' => sub {
    my($c,$args) = @_;
    my $id = $c->request->param("circle_id");
    my $type = $c->request->param("circle_type");
    my $comment = $c->request->param("circle_comment");
    my $member_id = $c->loggin_user->{member_id};
    $c->hirukara->update_circle_info(member_id => $member_id, circle_id => $id, circle_type => $type, comment => $comment);
    $c->redirect("/circle/$id");
};

sub _checklist  {
    my($c,$cond) = @_;
    $cond ||= {};
    my $user = $c->session->get("user")
        or return $c->redirect("/");

    ## TODO: put on cache :-)
    my $members = [ map { $_->member_id } $c->db->search_by_sql("SELECT DISTINCT member_id FROM member ORDER BY member_id")->all ];
    my $days    = [ map { $_->day } $c->db->search_by_sql("SELECT DISTINCT day FROM circle ORDER BY day")->all ];
    my $areas   = [ Hirukara::Constants::Area->areas ];

    my @conditions = (
        day => {
            label => "日数", 
            method => 1,
        },
        area => {
            label => "エリア",
            method => sub {
                my($param,$cond) = @_;
                my $syms = Hirukara::Constants::Area->get_syms_by_area($param);
                $cond->{"circle.circle_sym"} = { in => $syms };
            },
        },

        circle_type => {
            label => "サークル属性",
            method => undef,
            cond_format => sub {
                my($param) = @_;
                my $type = Hirukara::Constants::CircleType::lookup($param);
                $type->{label};
            },
        },

        member_id => {
            label => "メンバー",
            method => sub {
                my($param,$cond) = @_;
                my @checks = map { $_->circle_id } $c->hirukara->database->search(checklist => { member_id => $param });
                $cond->{"circle.id"} = { in => \@checks };
            },
        },
    );

    my @conds;
    while (my($column,$data) = splice @conditions, 0, 2)  {
        my $param  = $c->request->param($column) or next;
        my $method = $data->{method};
        my $label  = $data->{label};

        if (ref $method eq 'CODE')  {
            $method->($param,$cond);
        }
        else    {
            $cond->{$column} = $param;
        }
        
        my $display_cond = $data->{cond_format} ? $data->{cond_format}->($param) : $param;
        push @conds, sprintf "%s=%s", $label, $display_cond;
    }

    my $ret = $c->hirukara->get_checklists($cond);
    push @conds, "なし" unless @conds;

    $c->fillin_form($c->req);
    return $c->render('view.tt', {
        res => $ret,
        days => $days,
        areas => $areas,
        members => $members,
        conditions => sprintf("検索条件:%s", join ", " => @conds),
        circle_types => [Hirukara::Constants::CircleType->circle_types],
    });
}

get '/view'     => sub { my $c = shift; _checklist($c) };

get '/assign'   => sub {
    my $c = shift;
    my @members = map { $_->member_id } $c->db->search_by_sql("SELECT DISTINCT member_id FROM member")->all;
    my @comikets = map { $_->comiket_no } $c->db->search_by_sql("SELECT DISTINCT comiket_no FROM circle")->all;
    $c->render('assign_func.tt', {
        members => \@members,
        comikets => \@comikets,
        assign => [ $c->db->search("assign_list")->all ],
    });
};

get '/assign/view'   => sub {
    my $c = shift;
    my $ret = $c->hirukara->get_checklists;
    my @members = map { $_->member_id } $c->db->search_by_sql("SELECT DISTINCT member_id FROM member")->all;
    my @comikets = map { $_->comiket_no } $c->db->search_by_sql("SELECT DISTINCT comiket_no FROM circle")->all;
    return $c->render('assign.tt', {
        res => $ret,
        assign => [ $c->db->search("assign_list")->all ],
    });
};

post '/assign/create'   => sub {
    my $c = shift;
    my $no = $c->request->param("comiket_no");
    $c->db->insert(assign_list => { name => time, member_id => undef, comiket_no => $no });
    $c->redirect("/assign");
};

post '/assign/update'   => sub {
    my $c = shift;
    my $assign_id = $c->request->param("assign_list_id");
    my $assign = $c->db->single(assign_list => { id => $assign_id });

    if ( my @circles = $c->request->param("circle") )   {
        for my $id (@circles)   {
            if ( !$c->db->single(assign => { assign_list_id => $assign->id, circle_id => $id }) )    {
                my $list = $c->db->insert(assign => { assign_list_id => $assign->id, circle_id => $id });
            }
        }
    }

    if ( my $member_id = $c->request->param("assign_member_id") )  {
        $assign->member_id($member_id);
        $assign->update;

        infof "ASSIGN_MEMBER_UPDATE: assign_id=%s, change_member_id=%s", $assign->id, $member_id;
    }

    $c->redirect("/assign");
};

get '/logout' => sub {
    my $c = shift;
    my $user = $c->session->get("user");
    infof "LOGOUT: member_id=%s", $user->{member_id};
    $c->session->expire;
    $c->redirect("/");
};

post '/checklist/add' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->hirukara->create_checklist(member_id => $member_id, circle_id => $circle_id);
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->hirukara->delete_checklist(member_id => $member_id, circle_id => $circle_id);
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete_all' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    $c->hirukara->delete_all_checklists(member_id => $member_id);
    $c->redirect("/view?member_id=$member_id");
};

post '/checklist/update' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    my $count = $c->request->param("order_count");
    my $comment = $c->request->param("checklist_comment");

    my $check = $c->hirukara->update_checklist_info(
        member_id   => $member_id,
        circle_id   => $circle_id,
        order_count => $count,
        comment     => $comment,
    );

    return $check
        ? $c->redirect("/circle/$circle_id")
        : $c->create_simple_status_page(403, "Not exist");
};

post '/upload' => sub {
    my $c = shift;
    my $file = $c->req->upload("checklist");

    unless ($file)  {
        return $c->create_simple_status_page(403, "Please upload a file");
    }

    my $path = $file->path;
    my $member_id = $c->session->get('user')->{member_id};
    my $dest = $c->checklist_dir->file(sprintf "%s_%s.csv", time, $member_id);

    copy $path, $dest;
    infof "UPLOAD_RUN: member_id=%s, file=%s, copy_to=%s", $member_id, $path, $dest;

    my $csv    = $c->hirukara->parse_csv($path);
    my $result = $c->hirukara->merge_checklist($csv,$member_id);
    $result->run_merge;

    $c->session->set(uploaded_checklist => $result->merge_results);

    return $c->redirect("/result");
};

get "/result" => sub {
    my $c = shift;
    my $result = $c->session->get("uploaded_checklist");

    unless ($result)    {
        return $c->redirect("/view");
    }

    ## display result is only once
    $c->session->remove("uploaded_checklist");
    $c->render("result.tt", { result => $result });
};

get "/export/excel" => sub {
    my $c = shift;
    my $e = $c->hirukara->get_xls_file;
    my $fh = $e->file;
    my $user = $c->loggin_user;

    infof "EXCEL_OUTPUT: user=%s, file=%s", $user->{member_id}, $fh->filename;
    my @header = ("content-disposition", sprintf "attachment; filename=%s.xlsx", $user->{member_id});
    return $c->create_response(200, \@header, $fh);
};

get "/export/checklist" => sub {
    my $c = shift;
    my $csv = $c->hirukara->export_csv;
    $c->create_response(200, undef, $csv);
};

get "/log" => sub {
    my $c = shift;
    my $it = $c->hirukara->get_action_logs;
    my @logs = map {
        my $r = Hirukara::ActionLog->extract_log($_);
        $r->{created_at} = $_->created_at;
        $r;
    } $it->all;

    $c->render("log.tt", { logs => \@logs });
};

__PACKAGE__->load_plugin('Web::CSRFDefender' => { post_only => 1 });
__PACKAGE__->load_plugin('Web::FillInFormLite');
__PACKAGE__->load_plugin('Web::Auth', {
    module => 'Twitter',
    on_error => sub {
        my($c,$reason) = @_;
        infof "LOGIN_FAIL: reason=%s", $reason;
        return $c->create_simple_status_page(403, "OAuth login fail");
    },
    on_finished => sub {
        my($c,$access_token,$access_secret,$user_id,$screen_name) = @_;
        infof "LOGIN_SUCCESS: user_id=%s, screen_name=%s", $user_id, $screen_name;

        my $conf = $c->config->{Auth}->{Twitter};
        my $n = Net::Twitter::Lite::WithAPIv1_1->new(
            consumer_key    => $conf->{consumer_key},
            consumer_secret => $conf->{consumer_secret},
            ssl             => 1,
        );

        $n->access_token($access_token);
        $n->access_token_secret($access_secret);

        my $me        = $n->verify_credentials;
        my $image_url = $me->{profile_image_url};
        my $member    = $c->hirukara->get_member_by_id(id => $user_id)
                        || $c->hirukara->create_member(id => $user_id, member_id => $screen_name, image_url => $image_url);
        
        $c->session->set(user => {
            member_id         => $screen_name,
            profile_image_url => $image_url,
        });

        $c->redirect("/");
    },
});

__PACKAGE__->load_plugin('Web::HTTPSession', {
   state => 'Cookie',
   store => sub {
     use HTTP::Session::Store::File;
     HTTP::Session::Store::File->new(dir => './session');
   }
});

sub __auth {
    my($c,$auth,$p) = @_;
    if ($c->loggin_user) { $auth->success }
    else                 { $auth->failed  }
    return;
}

__PACKAGE__->load_plugin(
    'Web::Auth::Path' => {
        paths => [
            qr{^/log}    => \&__auth,
            qr{^/circle} => \&__auth,
            qr{^/view}   => \&__auth,
            qr{^/upload} => \&__auth,
            qr{^/result} => \&__auth,
            qr{^/checklist} => \&__auth,
        ],
    },
);

infof "APPLICATION_START: ";
__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);
