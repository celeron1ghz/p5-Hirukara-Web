use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.12';

use Hirukara;
use Hirukara::Parser::CSV;
use Hirukara::Lite::Merge;
use Teng::Schema::Loader;
use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;
use Hirukara::Util;
use Hirukara::AreaLookup;

__PACKAGE__->template_options(
    'function' => {
        circle_space => Hirukara::Util->can('get_circle_space'),
        area_lookup  => Hirukara::AreaLookup->can('lookup'),
    }
);

sub loggin_user {
    my($c) = @_;
    $c->session->get("user");
}

sub hirukara    {
    my $self = shift;

    $self->{hirukara} //= do {
        Hirukara->new(database => $self->db);
    };
}

sub db {
    my $self = shift;

    $self->{db} //= do {
        my $conf = $self->config->{Teng} or die "config Teng missing";
        my $db = Teng::Schema::Loader->load(%$conf);
        $db->load_plugin("SearchJoined");
        $db;
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

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;

    my $user = $c->session->get("user");
    my $circle = $c->hirukara->get_circle_by_id($args->{circle_id})
        or return $c->create_simple_status_page(404, "Circle Not Found");

    my $it = $c->hirukara->get_checklists_by_circle_id($circle->id);
    my $my = $c->hirukara->get_checklist({ circle_id => $circle->id, member_id => $user->{member_id} });

    $c->render("circle.tt", { circle => $circle, checklist => $it, my => $my });
};

sub _checklist  {
    my($c,$cond) = @_;
    my $user = $c->session->get("user")
        or return $c->redirect("/");

    ## TODO: put on cache :-)
    my $syms = [ map { $_->circle_sym } $c->db->search_by_sql("SELECT DISTINCT circle_sym FROM circle ORDER BY circle_sym")->all ];

    for my $key (qw/day area circle_sym/)   {
        my $val = $c->request->param($key);
        $cond->{$key} = $val if $val;
    }

    my $ret = $c->hirukara->get_checklists($cond);

    $c->fillin_form($c->req);
    return $c->render('view.tt', { res => $ret, syms => $syms });
}

get '/view' => sub {
    my $c = shift;
    _checklist($c);
};

get '/view/me' => sub {
    my $c = shift;
    _checklist($c, { "checklist.member_id" => $c->loggin_user->{member_id} });
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

    my $check = $c->hirukara->get_checklist({ member_id => $member_id, circle_id => $circle_id });

    if ($check)    {
        return $c->create_simple_status_page(403, "Already exist");
    }

    $c->db->insert(checklist => {
        member_id => $member_id,
        circle_id => $circle_id,
        count     => 1,
        assign_id => 1,
    });

    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");

    my $check = $c->hirukara->get_checklist({ member_id => $member_id, circle_id => $circle_id });

    if (!$check)    {
        return $c->create_simple_status_page(403, "Not exist");
    }

    $check->delete;
    $c->redirect("/circle/$circle_id");
};

get '/upload' => sub { my $c = shift; $c->render("upload.tt") };

post '/upload' => sub {
    my $c = shift;
    my $file = $c->req->upload("checklist");

    unless ($file)  {
        return $c->create_simple_status_page(403, "Please upload a file");
    }

    my $path = $file->path;
    my $member_id = $c->session->get('user')->{member_id};

    infof "UPLOAD_RUN: member_id=%s, file=%s", $member_id, $path;

    my $csv = Hirukara::Parser::CSV->read_from_file($path);

    my $result = Hirukara::Lite::Merge->new(database => $c->db, csv => $csv, member_id => $member_id);
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

#__PACKAGE__->load_plugin('Web::CSRFDefender' => { post_only => 1 });
__PACKAGE__->load_plugin('Web::FillInFormLite');
# __PACKAGE__->load_plugin('DBI');
# __PACKAGE__->load_plugin('Web::JSON');

__PACKAGE__->load_plugin('Web::Auth', {
    module => 'Twitter',
    on_error => sub {
        my($c,$reason) = @_;
        infof "LOGIN_FAIL: reason=%s", $reason;

        return $c->create_response(403, undef, "error");
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

        my $me = $n->verify_credentials;
        my $image_url = $me->{profile_image_url};

        if ( my $member = $c->db->single('member' => { member_id => $screen_name }) )    {
            $member->image_url($me->{profile_image_url});
            $member->update;
        } else {
            $c->db->insert(member => { member_id => $screen_name, image_url => $image_url });
        }
        
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
            qr{^/circle} => \&__auth,
            qr{^/view}   => \&__auth,
            qr{^/upload} => \&__auth,
            qr{^/result} => \&__auth,
        ],
    },
);

__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);

