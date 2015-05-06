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
use Hirukara::Constants::Area;
use Hirukara::Constants::CircleType;
use Encode;
use Hirukara::Exception;
use Config::PL;

__PACKAGE__->template_options(
    'function' => {
        area_lookup        => Hirukara::Constants::Area->can('lookup'),
        circle_type_lookup => Hirukara::Constants::CircleType->can('lookup'),
        sprintf => \&CORE::sprintf,
        time    => \&CORE::localtime,
    }
);

my $hirukara;

## accessors
sub config      { +{ config_do 'config.pl' } }
sub hirukara    { my $c = shift; $hirukara //= do { Hirukara->load($c->config) } }
sub db          { my $c = shift; $c->hirukara->database }
sub loggin_user { my $c = shift; $c->session->get("user") }

sub dispatch {
    my ($c) = @_;
    my $router = router;

    if (my $p = $router->match($c->request->env)) {
        my $ret;
        eval { $ret = $p->{code}->( $c, $p ) };

        if (my $error = $@) {
            warnf "Error thrown in calling '%s': class=%s, message=%s"
                , $c->request->path
                , ref $error
                , encode_utf8 $error->can("message") ? $error->message : $error;

            if (Hirukara::Exception->caught($error))    {
                return $c->create_simple_status_page(403, encode_utf8 $error->message);
            }

            if (Moose::Exception->Exception::Tiny::caught($error))  {
                return $c->create_simple_status_page(403, encode_utf8 $error->message);
            }
        }

        return $ret;
    } else {
        if ($router->method_not_allowed) {
            my $content = '405 Method Not Allowed';
            return $c->create_response(
                405,
                [
                    'Content-Type'   => 'text/plain; charset=utf-8',
                    'Content-Length' => length($content),
                ],
                [$content]
            );
        } else {
            return $c->res_404();
        }
    }
};

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

    $param->{members}  = [ $db->search_by_sql("SELECT * FROM member")->all ];
    $param->{comikets} = [ map { $_->comiket_no } $db->search_by_sql("SELECT DISTINCT comiket_no FROM circle")->all ];
    $param->{current_exhibition} = $c->hirukara->exhibition;
    $c->SUPER::render($file,$param);
}


## login
get '/' => sub {
    my $c = shift;

    $c->loggin_user
        ? $c->render("notice.tt", {
            notice => $c->hirukara->run_command('notice_select'),
            counts => $c->hirukara->run_command(statistic_single => { member_id => $c->loggin_user->{member_id} }),
            assign => $c->hirukara->run_command(assign_search    => { member_id => $c->loggin_user->{member_id} }),
        })
        : $c->render("login.tt");
};


## logout
get '/logout' => sub {
    my $c = shift;
    my $user = $c->session->get("user");
    infof "LOGOUT: member_id=%s", $user->{member_id};
    $c->session->expire;
    $c->redirect("/");
};


## circle/checklist
get '/search' => sub {
    my $c = shift;
    my $cond = $c->hirukara->get_condition_object(req => $c->req);
    my $ret;

    if (my $where = $cond->{condition}) {
        $ret = $c->hirukara->run_command(circle_search => { where => $where });
    }

    $c->fillin_form($c->req);
    $c->render("search.tt", {
        res => $ret,
        conditions => $cond->{condition_label},
        condition => $cond->{condition},
    });
};

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;
    my $circle = $c->hirukara->run_command(circle_single => { circle_id => $args->{circle_id} })
        or return $c->create_simple_status_page(404, "Circle Not Found");

    my $it = $c->hirukara->run_command(checklist_search => { where => { "circle_id" => $circle->id } });
    my @chk;
    while(my @col = $it->next) { push @chk, \@col }

    my $my = $c->hirukara->run_command(checklist_single => { circle_id => $circle->id, member_id => $c->loggin_user->{member_id} });

    $c->fillin_form({
        circle_type       => $circle->circle_type,
        circle_comment    => $circle->comment,
        checklist_comment => $my ? $my->comment : "",
        order_count       => $my ? $my->count : 0,
    });

    $c->render("circle.tt", {
        circle    => $circle,
        checklist => \@chk,
        circle_type => Hirukara::Constants::CircleType::lookup($circle->circle_type) || undef,
    });
};

post '/circle/update' => sub {
    my($c,$args) = @_;
    my $id = $c->request->param("circle_id");

    $c->hirukara->run_command(circle_update => {
        member_id   => $c->loggin_user->{member_id},
        circle_id   => $id,
        circle_type => $c->request->param("circle_type"),
        comment     => $c->request->param("circle_comment"),
    });

    $c->redirect("/circle/$id");
};

get '/assign' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    $c->fillin_form($c->req);
    $c->render("assign.tt", {
        assign => $c->hirukara->run_command(assign_search => {
            member_id  => $user->{member_id},
        }),
    });
};

get '/checklist' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    my $cond = $c->hirukara->get_condition_object(req => $c->req);
    my $ret = $c->hirukara->run_command(checklist_joined => { where => $cond->{condition} });

    $c->fillin_form($c->req);

    return $c->render('checklist.tt', {
        res        => $ret,
        conditions => $cond->{condition_label},
        assigns    => $c->hirukara->run_command('assign_search'),
    });
};

post '/checklist/add' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->hirukara->run_command(checklist_create => { member_id => $member_id, circle_id => $circle_id });
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->hirukara->run_command(checklist_delete => { member_id => $member_id, circle_id => $circle_id });
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete_all' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    $c->hirukara->run_command(checklist_deleteall => { member_id => $member_id });
    $c->redirect("/view?member_id=$member_id");
};

post '/checklist/update' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");

    $c->hirukara->run_command(checklist_update => {
        member_id   => $member_id,
        circle_id   => $circle_id,
        count       => $c->request->param("order_count"),
        comment     => $c->request->param("checklist_comment"),
    });

    $c->redirect("/circle/$circle_id")
};

post "/checklist/bulk_operation" => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my @create = $c->req->param("create");
    my @delete = $c->req->param("delete");

    $c->hirukara->run_command(checklist_bulkoperation => {
        member_id => $member_id,
        create_chk_ids => \@create,
        delete_chk_ids => \@delete,
    });

    $c->redirect("/checklist?member_id=$member_id");
};

post '/upload' => sub {
    my $c = shift;
    my $file = $c->req->upload("checklist")
        or return $c->create_simple_status_page(403, "Please upload a file");

    my $member_id = $c->session->get('user')->{member_id};
    my $path = $file->path;
    my $dest = $c->hirukara->checklist_dir->child(sprintf "%s_%s.csv", time, $member_id);

    copy $path, $dest;
    infof "UPLOAD_RUN: member_id=%s, file=%s, copy_to=%s", $member_id, $path, $dest;

    my $result = $c->hirukara->run_command(checklist_parse => { csv_file => $path, member_id => $member_id });
    $c->render("result.tt", { result => $result->merge_results });
};

get "/{output_type}/export/{file_type}" => sub {
    my($c,$args) = @_;
    my $user     = $c->loggin_user;
    my $split_by = $args->{output_type} || 'checklist';

    my $ret = $c->hirukara->run_command('checklist_export', {
        where      => $c->req->parameters,
        type       => $args->{file_type},
        split_by   => $split_by,
        template_var => {
            member_id => $user->{member_id},
        },
    });

    my $filename = encode_utf8 sprintf "%s_%s.%s", $c->hirukara->exhibition, $split_by, $ret->{extension};
    my @header = ("content-disposition", sprintf "attachment; filename=$filename");

    close $ret->{file};
    open my $fh, $ret->{file} or die;
    $c->create_response(200, \@header, $fh);
};


## statistics page
get '/members' => sub {
    my $c = shift;
    $c->render("members.tt", { statistics => $c->hirukara->run_command('statistic_select') });
};


## admin page
get "/admin/log" => sub {
    my $c = shift;
    $c->render("admin/log.tt", { logs => $c->hirukara->run_command('actionlog_select', { page => $c->req->param("page") || 0 }) });
};

get '/admin/notice' => sub {
    my $c = shift;
    my $key = $c->req->param("key");
    my $notice;

    if ($key)   {
        $notice = $c->hirukara->run_command('notice_single', { key => $key });

        if (@$notice)   {
            $c->fillin_form($notice->[0]->get_columns);
        }
    }

    $c->render("admin/notice.tt", {
        noticies => $c->hirukara->run_command('notice_select'),
        $key ? (notice => $notice) : (),
    });
};

post '/admin/notice' => sub {
    my $c = shift;
    $c->hirukara->run_command(notice_update => {
        key   => $c->req->param("key"),
        title => $c->req->param("title"),
        text  => $c->req->param("text"),
        member_id => $c->loggin_user->{member_id},
    });
    $c->redirect("/admin/notice");
};

get '/admin/assign' => sub {
    my $c = shift;
    $c->render('admin/assign_list.tt', {
        assign => $c->hirukara->run_command('assign_search')
    });
};

get '/admin/assign/view'   => sub {
    my $c = shift;
    my $cond = $c->hirukara->get_condition_object(req => $c->req);
    my $ret;

    if (my $where = $cond->{condition}) {
        $ret = $c->hirukara->run_command(checklist_joined => { where => $cond->{condition} });
    }

    $c->fillin_form($c->req);

    return $c->render('admin/assign.tt', {
        res => $ret,
        assign => $c->hirukara->run_command('assign_search'),
        conditions => $cond->{condition_label},
        condition => $cond->{condition},
    });
};

post '/admin/assign/create'   => sub {
    my $c = shift;
    my $no = $c->request->param("comiket_no");
    $c->hirukara->run_command('assignlist_create');
    $c->redirect("/admin/assign");
};

post '/admin/assign/update'   => sub {
    my $c = shift;

    $c->hirukara->run_command(assign_create => {
        assign_list_id  => $c->request->param("assign_id"),
        circle_ids => [ $c->request->param("circle") ],
    });

use URI;
    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/admin/assign/view?$param");
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

    $c->hirukara->run_command(assignlist_update => {
        assign_id        => $assign_id,
        assign_member_id => $c->request->param("assign_member"),
        assign_name      => $c->request->param("assign_name"),
        member_id        => $c->loggin_user->{member_id},
    });

    $c->redirect("/admin/assign");
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

        my $member    = $c->hirukara->run_command(member_select => { member_id => $screen_name })
                        || $c->hirukara->run_command(member_create => {
                            id => $user_id,
                            member_id => $screen_name,
                            member_name => $screen_name,
                            image_url => $image_url
                        });
        
        $c->session->set(user => {
            member_id         => $screen_name,
            member_name       => $member->member_name,
            profile_image_url => $image_url,
        });

        $c->redirect("/");
    },
});

use HTTP::Session::Store::Memcached;
use HTTP::Session::State::Cookie;
use Cache::Memcached::Fast;

__PACKAGE__->load_plugin('Web::HTTPSession', {
    state => sub {
        my $c = shift;
        my $args = $c->config->{Session}->{state} or die "config Session.state missing";
        infof "INIT_SESSION: state_args=%s", ddf($args);
        HTTP::Session::State::Cookie->new(@$args);
    },
    store => sub {
        my $c = shift;
        my $args = $c->config->{Session}->{store} or die "config Session.store missing";
        infof "INIT_SESSION: store_args=%s", ddf($args);
        HTTP::Session::Store::Memcached->new( memd => Cache::Memcached::Fast->new($args) );
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
        my $role = $c->hirukara->run_command(auth_single => { member_id => $member_id, role_type => 'assign' });

        unless ($role)  {
            $c->create_simple_status_page(403, encode_utf8 "ﾇﾇﾝﾇ");
        }
    }
});

__PACKAGE__->hirukara; ## initialize at loading
__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);
