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
use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;
use Hirukara;
use Hirukara::Util;
use Hirukara::Constants::Area;
use Hirukara::Constants::CircleType;
use Hirukara::SearchCondition;
use Encode;
use Text::Markdown;

my %members;
    
__PACKAGE__->template_options(
    'function' => {
        markdown     => sub {
            my $val = shift;
            $val =~ s|<(/?script)>|&lt;$1&gt;|g;
            Text::Markdown::markdown($val);
        },
        circle_space => Hirukara::Util->can('get_circle_space'),
        area_lookup  => Hirukara::Constants::Area->can('lookup'),
        circle_type_lookup => Hirukara::Constants::CircleType->can('lookup'),
        assign_list_label  => Hirukara::Util->can('get_assign_list_label'),
        sprintf => \&CORE::sprintf,
        time    => \&CORE::localtime,
        member_name  => sub {
            my $member_id = shift || '';
            $members{$member_id} || "$member_id";
        },
    }
);

my $hirukara;

%members = map { $_->member_id => $_->display_name } __PACKAGE__->db->search("member");

## accessors
sub hirukara    { my $c = shift; $hirukara //= do { Hirukara->load($c->config) } }
sub db          { my $c = shift; $c->hirukara->database }
sub loggin_user { my $c = shift; $c->session->get("user") }
sub circle      { my $c = shift; $c->model('+Hirukara::Model::Circle') }
sub checklist   { my $c = shift; $c->model('+Hirukara::Model::Checklist') }
sub auth        { my $c = shift; $c->model('+Hirukara::Model::Auth') }
sub action_log  { my $c = shift; $c->model('+Hirukara::Model::ActionLog') }
sub member      { my $c = shift; $c->model('+Hirukara::Model::Member') }
sub statistic   { my $c = shift; $c->model('+Hirukara::Model::Statistic') }
sub notice      { my $c = shift; $c->model('+Hirukara::Model::Notice') }
sub assign      { my $c = shift; $c->model('+Hirukara::Model::Assign') }


sub get_condition_value {
    my($c) = @_;
    my $ret = Hirukara::SearchCondition->run($c->req->parameters);
    infof "SEARCH_CONDITION: val='%s'", encode_utf8 $ret->{condition_label};
    $ret;
}

sub render  {
    my($c,$file,$param) = @_;
    my $db = $c->db;
    $param ||= {};
    $param->{user} = $c->session->get("user");
    $param->{constants} = {
        days         => [ map { $_->day } $db->search_by_sql("SELECT DISTINCT day FROM circle ORDER BY day")->all ],
        areas        => [Hirukara::Constants::Area->areas],
        circle_types => [Hirukara::Constants::CircleType->circle_types],
    };

    $param->{members}  = [ map { $_->member_id } $db->search_by_sql("SELECT DISTINCT member_id FROM member ORDER BY member_id")->all ];
    $param->{comikets} = [ map { $_->comiket_no } $db->search_by_sql("SELECT DISTINCT comiket_no FROM circle")->all ];
    $c->SUPER::render($file,$param);
}

get '/' => sub {
    my $c = shift;

    $c->session->get("user")
        ? $c->render("notice.tt", { notice => $c->notice->get_notice })
        : $c->render("login.tt");
};

get '/search' => sub {
    my $c = shift;
    my $cond = $c->get_condition_value;
    my @ret;

    if (my $where = $cond->{condition}) {
        @ret = $c->circle->search($where);
    }

    $c->fillin_form($c->req);
    $c->render("search.tt", {
        res => \@ret,
        conditions => $cond->{condition_label},
        condition => $cond->{condition},
    });
};

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;
    my $user = $c->session->get("user");
    my $circle = $c->circle->get_circle_by_id(id => $args->{circle_id})
        or return $c->create_simple_status_page(404, "Circle Not Found");

    my $it = $c->checklist->get_checklists_by_circle_id($circle->id);
    my $my = $c->checklist->get_checklist({ circle_id => $circle->id, member_id => $user->{member_id} });

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

    $c->circle->update_circle_info(
        member_id   => $c->loggin_user->{member_id},
        circle_id   => $id,
        circle_type => $c->request->param("circle_type"),
        comment     => $c->request->param("circle_comment"),
    );

    $c->redirect("/circle/$id");
};

get '/checklist' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    my $cond = $c->get_condition_value;
    my $ret = $c->checklist->get_checklists($cond->{condition});

    $c->fillin_form($c->req);

    return $c->render('checklist.tt', {
        res        => $ret,
        conditions => $cond->{condition_label},
        assigns    => $c->assign->get_assign_lists,
    });
};

get '/admin/assign' => sub {
    my $c = shift;
    $c->render('admin/assign_list.tt', {
        assign => $c->hirukara->get_assign_lists_with_count,
    });
};

get '/admin/assign/view'   => sub {
    my $c = shift;
    my $cond = $c->get_condition_value;
    my $ret = $c->checklist->get_checklists($cond->{condition});

    $c->fillin_form($c->req);

    return $c->render('admin/assign.tt', {
        res => $ret,
        assign => $c->assign->get_assign_lists,
    });
};

post '/admin/assign/create'   => sub {
    my $c = shift;
    my $no = $c->request->param("comiket_no");
    $c->hirukara->create_assign_list(comiket_no => $no);
    $c->redirect("/admin/assign");
};

post '/admin/assign/update'   => sub {
    my $c = shift;
    my $circle_id = $c->request->param("circle_id");
    my $assign_id = $c->request->param("assign_id");

    if ( my @circles = $c->request->param("circle") )   {
        $c->assign->update_assign(assign_id  => $assign_id, circle_ids => [ @circles ]);
    }

use URI;
    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/admin/assign/view?$param");
};

get '/assign' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    $c->render("assign.tt", {
        assign => $c->assign->get_assign_lists({ member_id => $user->{member_id} }),
    });
};

post '/admin/assign_info/delete'   => sub {
    my $c = shift;
    my $id = $c->request->param("assign_id");
    my $cnt = $c->db->delete(assign => { id => $id });
    infof "DELETE_ASSIGN: assign_id=%s, count=%s", $id, $cnt;

    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/admin/assign/view?$param");
};

post '/admin/assign_info/update'   => sub {
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

    $c->redirect("/admin/assign");
};

get '/members' => sub {
    my $c = shift;

    $c->render("members.tt", {
        scores  => $c->statistic->get_score,
        counts  => $c->statistic->get_counts,
        score_members => [$c->statistic->get_members],
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
    $c->checklist->create_checklist(member_id => $member_id, circle_id => $circle_id);
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->checklist->delete_checklist(member_id => $member_id, circle_id => $circle_id);
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete_all' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    $c->checklist->delete_all_checklists(member_id => $member_id);
    $c->redirect("/view?member_id=$member_id");
};

post '/checklist/update' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");

    my $check = $c->checklist->update_checklist_info(
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
    my $dest = $c->hirukara->checklist_dir->child(sprintf "%s_%s.csv", time, $member_id);

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

get "/{output_type}/export/{file_type}" => sub {
    my($c,$args) = @_;
    my $class = $EXPORT_TYPE{$args->{file_type}} or return $c->res_403;
    my $user  = $c->loggin_user;
    my $cond  = $c->get_condition_value;
    my $checklists = $c->checklist->get_checklists($cond->{condition});
    my $type = $args->{output_type};

    infof "EXPORT_CHECKLIST: file_type=%s, output_type=%s, member_id=%s", $class, $type, $user->{member_id};

    my $self = $c->hirukara->checklist_export_as($class,$checklists,
        split_by => $type,
        template_var => {
            title     => $cond->{condition_label},
            member_id => $user->{member_id},
        },
    );

    my $content = $self->process;
    my @header = ("content-disposition", sprintf "attachment; filename=%s_%s.%s", $user->{member_id}, time, $self->get_extension);
    $c->create_response(200, \@header, $content);
};

get "/admin/log" => sub {
    my $c = shift;
    $c->render("log.tt", { logs => $c->action_log->get_action_logs });
};

get '/admin/notice' => sub {
    my $c = shift;
    my $notice = $c->notice->get_notice;
    $c->render("admin/notice.tt", { notice => $notice });
};

post '/admin/notice' => sub {
    my $c = shift;
    my $text = $c->req->param("text");

    $c->hirukara->update_notice(
        member_id => $c->loggin_user->{member_id},
        text      => $text,
    );

    $c->redirect("/admin/notice");
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
        my $member    = $c->member->get_member_by_id(id => $user_id)
                        || $c->member->create_member(id => $user_id, member_id => $screen_name, image_url => $image_url);
        
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

__PACKAGE__->add_trigger(BEFORE_DISPATCH => sub {
    my $c = shift;
    my $path = $c->req->path_info;
    return if $path eq '/';
    return $c->create_simple_status_page(403, "Please login.") unless $c->loggin_user;
});

__PACKAGE__->add_trigger(BEFORE_DISPATCH => sub {
    my $c = shift;
    my $path = $c->req->path_info;

    if ($path =~ m|^/admin/|)   {
        my $member_id = $c->loggin_user->{member_id};

        unless ( $c->auth->has_role(member_id => $member_id, role_type => 'assign') )    {
            $c->create_simple_status_page(403, encode_utf8 "ﾇﾇﾝﾇ");
        }
    }
});

infof "APPLICATION_START: ";

__PACKAGE__->load_plugin('Model');
__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);
