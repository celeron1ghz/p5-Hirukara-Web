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

my %members;
    
__PACKAGE__->template_options(
    'function' => {
        circle_space => Hirukara::Util->can('get_circle_space'),
        area_lookup  => Hirukara::Constants::Area->can('lookup'),
        circle_type_lookup => Hirukara::Constants::CircleType->can('lookup'),
        assign_list_label  => Hirukara::Util->can('get_assign_list_label'),
        sprintf => \&CORE::sprintf,
        time    => \&CORE::localtime,
        member_name  => sub {
            my $member_id = shift;
            $members{$member_id} || "$member_id";
        },
    }
);

my $db;
my $hirukara;
my $auth;

%members = map { $_->member_id => $_->display_name } __PACKAGE__->db->search("member");

sub loggin_user {
    my($c) = @_;
    $c->session->get("user");
}

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

sub auth    {
    my $self = shift;
    $auth //= do {
        my $conf = $self->config->{"Hirukara::Auth"} or die "config Hirukara::Auth missing";
        Hirukara::Auth->new(roles => %$conf);
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
    $param->{constants} = {
        days         => $c->get_cache("days"),
        areas        => [Hirukara::Constants::Area->areas],
        circle_types => [Hirukara::Constants::CircleType->circle_types],
    };

    $c->SUPER::render($file,$param);
}

my %CACHE_FETCH = (
    members => sub {
        my $db = shift;
        [ map { $_->member_id } $db->search_by_sql("SELECT DISTINCT member_id FROM member ORDER BY member_id")->all ];
    },

    days => sub {
        my $db = shift;
        [ map { $_->day } $db->search_by_sql("SELECT DISTINCT day FROM circle WHERE day <> 0 ORDER BY day")->all ];
    },

    comikets => sub {
        my $db = shift;
        [ map { $_->comiket_no } $db->search_by_sql("SELECT DISTINCT comiket_no FROM circle")->all ];
    },
);


my %CACHE;

sub get_cache   {
    my($c,$key) = @_;

    if ( my $ret = $CACHE{$key} )  {
        debugf "CACHE_HIT: key=%s", $key;
        return $ret;
    }
    else    {
        debugf "CACHE_MISS: key=%s", $key;
        return $CACHE{$key} = $CACHE_FETCH{$key}->($c->db);
    }
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
        circle_type => Hirukara::Constants::CircleType::lookup($circle->circle_type),
    });
};

post '/circle/update' => sub {
    my($c,$args) = @_;
    my $id = $c->request->param("circle_id");

    $c->hirukara->update_circle_info(
        member_id   => $c->loggin_user->{member_id},
        circle_id   => $id,
        circle_type => $c->request->param("circle_type"),
        comment     => $c->request->param("circle_comment"),
    );

    $c->redirect("/circle/$id");
};


sub get_condition_value {
    my($c) = @_;

    my @conditions = (
        day => {
            label => "日数", 
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
            cond_format => sub {
                my($param) = @_;
                my $type = Hirukara::Constants::CircleType::lookup($param);
                $type->{label};
            },
        },

        member_id => {
            label => "メンバー",
            method => sub {
                my($param,$cond,$circle_id_cond) = @_;
                push @$circle_id_cond, sql_op("IN (SELECT circle_id FROM checklist WHERE member_id = ?)", [$param]);
            },
        },

        assign => {
            label => "割り当て",
            method => sub {
                my($param,$cond,$circle_id_cond) = @_;

                push @$circle_id_cond, $param eq "-1"
                    ? sql_op("IN (SELECT circle.id AS circle_id FROM circle LEFT JOIN assign ON circle.id = assign.circle_id WHERE assign.circle_id IS NULL)", [])
                    : sql_op("IN (SELECT circle_id FROM assign WHERE assign_list_id = ?)", [$param])
            },
            cond_format => sub {
                my($param) = @_;
                my $ret = $c->hirukara->database->single(assign_list => { id => $param }) or return "割当なし";
                sprintf "%s(%s)", $ret->name, $ret->member_id;
            },
        },
    );

    my @conds;
    my $user = $c->loggin_user;
    my $cond = {};
    my $circle_id_cond = [];

    while (my($column,$data) = splice @conditions, 0, 2)  {
        my $param  = $c->request->param($column) or next;
        my $method = $data->{method};
        my $label  = $data->{label};

        if (ref $method eq 'CODE')  {
            $method->($param,$cond,$circle_id_cond);
        }
        else    {
            $cond->{$column} = $param;
        }
        
        my $display_cond = $data->{cond_format} ? $data->{cond_format}->($param) : $param;
        push @conds, sprintf "%s=%s", $label, $display_cond;
    }

    push @conds, "なし" unless @conds;
    my $condition_string = join(", " => @conds);

use Encode;
use SQL::QueryMaker;

    infof "SEARCH_CONDITION: val='%s'", encode_utf8 $condition_string;

    $cond->{"circle.id"} = sql_and($circle_id_cond) if @$circle_id_cond;

    return {
        condition_string => $condition_string,
        condition => $cond,
    };
}

get '/view' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    my $cond = $c->get_condition_value;
    my $ret = $c->hirukara->get_checklists($cond->{condition});

    $c->fillin_form($c->req);
    return $c->render('view.tt', {
        res => $ret,
        members => $c->get_cache("members"),
        conditions => $cond->{condition_string},
        assigns => $c->hirukara->get_assign_lists,
    });
};

get '/assign' => sub {
    my $c = shift;
    $c->render('assign_func.tt', {
        members => $c->get_cache("members"),
        comikets => $c->get_cache("comikets"),
        assign => $c->hirukara->get_assign_lists_with_count,
    });
};

get '/assign/view'   => sub {
    my $c = shift;
    my $cond = $c->get_condition_value;
    my $ret = $c->hirukara->get_checklists($cond->{condition});

    $c->fillin_form($c->req);
    return $c->render('assign.tt', {
        res => $ret,
        assign => $c->hirukara->get_assign_lists,
        members => $c->get_cache("members"),
    });
};

post '/assign/create'   => sub {
    my $c = shift;
    my $no = $c->request->param("comiket_no");
    $c->db->insert(assign_list => { name => "新規作成リスト", member_id => undef, comiket_no => $no });
    $c->hirukara->create_assign_list(comiket_no => $no);
    $c->redirect("/assign");
};

post '/assign/update'   => sub {
    my $c = shift;
    my $circle_id = $c->request->param("circle_id");
    my $assign_id = $c->request->param("assign_id");
    my $assign = $c->db->single(assign_list => { id => $assign_id });

    if ( my @circles = $c->request->param("circle") )   {
        for my $id (@circles)   {
            if ( !$c->db->single(assign => { assign_list_id => $assign->id, circle_id => $id }) )    {
                my $list = $c->db->insert(assign => { assign_list_id => $assign->id, circle_id => $id });
            }
        }
    }

use URI;
    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/assign/view?$param");
};

get '/assign/me' => sub {
    my $c = shift;
    $c->render("assign_my.tt", {
        assign => $c->hirukara->get_assign_lists_with_count,
    });
};

get '/assign/{id}'   => sub {
    my($c,$args) = @_;
    my $id = $args->{id};
    my $assign = $c->db->single(assign_list => { id => $id }) or return $c->res_403;
    my $user = $c->loggin_user;
    my $ret = $c->hirukara->get_checklists({ 'assign_list.id' => $id });

    my %assign;
    for my $row (@$ret) {
        my $favorite = $row->{favorite};

        for my $f (@$favorite) {
            push @{$assign{$f->member_id}}, $row;
        }
    }

    $c->render("assign_me.tt", {
        assign => $assign,
        data => \%assign,
    });
};

post '/assign_info/delete'   => sub {
    my $c = shift;
    my $id = $c->request->param("assign_id");
    my $cnt = $c->db->delete(assign => { id => $id });
    infof "DELETE_ASSIGN: assign_id=%s, count=%s", $id, $cnt;

    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/assign/view?$param");
};

post '/assign_info/update'   => sub {
    my $c = shift;
    my $assign_id = $c->request->param("assign_id");
    my $assign = $c->db->single(assign_list => { id => $assign_id });
    my $user = $c->loggin_user;

    $c->hirukara->update_assign_list(
        assign_id     => $assign_id,
        assign_member => $c->request->param("assign_member"),
        assign_name   => $c->request->param("assign_name"),
        member_id     => $user->{member_id},
    );

    $c->redirect("/assign");
};

get '/members' => sub {
    my $c = shift;

my $scores = $c->db->search_by_sql(<<SQL);
SELECT
    circle.day,
    circle.circle_sym,
    circle.circle_num,
    checklist.member_id
FROM circle
    JOIN checklist ON circle.id = checklist.circle_id
SQL

use Tie::IxHash;
tie my %pattern, 'Tie::IxHash';

    $pattern{qr/偽壁/}       = 5;
    $pattern{qr/壁/}         = 10;
    $pattern{qr/シャッター/} = 20;
    my %score;

    SCORE: for my $s ($scores->all)    {
        my $area = Hirukara::Constants::Area::lookup($s);

        keys %pattern; ## resetting iterator pointer
        while (my($re,$score) = each %pattern)  {
            if ($area =~ /$re/) {
                $score{$s->member_id} += $score;
                next SCORE;
            }
        }

        $score{$s->member_id}++;
    }

    $c->render("members.tt", {
        scores => \%score,
        counts => $c->db->single_by_sql(<<SQL)->get_columns,
SELECT
    COUNT(*) AS total_count,
    COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
    COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
    COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count
FROM checklist 
    LEFT JOIN circle    ON circle.id = checklist.circle_id
SQL

        members => [$c->db->search_by_sql(<<SQL)->all],
SELECT
    member.*,
    COUNT(checklist.member_id) AS total_count,
    COUNT(CASE WHEN circle.day = 1 THEN 1 ELSE NULL END) AS day1_count,
    COUNT(CASE WHEN circle.day = 2 THEN 1 ELSE NULL END) AS day2_count,
    COUNT(CASE WHEN circle.day = 3 THEN 1 ELSE NULL END) AS day3_count
FROM member
    LEFT JOIN checklist ON member.member_id = checklist.member_id
    LEFT JOIN circle    ON circle.id = checklist.circle_id
    GROUP BY member.member_id
    ORDER BY total_count DESC
SQL
    });
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

    my $check = $c->hirukara->update_checklist_info(
        member_id   => $member_id,
        circle_id   => $circle_id,
        order_count => $c->request->param("order_count"),
        comment     => $c->request->param("checklist_comment"),
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

my %EXPORT_TYPE = (
    checklist => "ComiketCsv",
    excel     => "Excel",
    pdf       => "PDF",
);

get "/checklist/export/{type}" => sub {
    my($c,$args) = @_;
    my $class = $EXPORT_TYPE{$args->{type}} or return $c->res_403;
    my $user  = $c->loggin_user;
    my $cond  = $c->get_condition_value;
    my $checklists = $c->hirukara->get_checklists($cond->{condition});

    infof "EXPORT_CHECKLIST: type=%s, member_id=%s", $class, $user->{member_id};
    my $self = $c->hirukara->checklist_export_as($class,$checklists);
    my $content = $self->process;
    my @header = ("content-disposition", sprintf "attachment; filename=%s_%s.%s", $user->{member_id}, time, $self->get_extension);
    $c->create_response(200, \@header, $content);
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
        my $c = shift;
        $c->config->{Session}->{store} or die "config Session.store missing";
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
            qr{^/view}      => \&__auth,
            qr{^/circle}    => \&__auth,
            qr{^/export}    => \&__auth,
            qr{^/log}       => \&__auth,
            qr{^/assign}    => \&__auth,
            qr{^/checklist} => \&__auth,
            qr{^/mypage}    => \&__auth,
            qr{^/result}    => \&__auth,
        ],
    },
);

infof "APPLICATION_START: ";
__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);
