use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.12';

sub load_config {
    my $c = shift;

    my $mode = $c->mode_name || 'development';

    pit_get("hirukara-lite");
}

use Config::Pit;
use Hirukara::Parser::CSV;
use Hirukara::Lite::Merge;
use Teng::Schema::Loader;
use Log::Minimal;
use Net::Twitter::Lite::WithAPIv1_1;

my $db = Teng::Schema::Loader->load( namespace => 'Hirukara::Lite::Database', connect_info => ["dbi:SQLite:moge.db", "", "", { sqlite_unicode => 1 }] );

$db->load_plugin("SearchJoined");

get '/' => sub {
    my $c = shift;

    if ( !$c->session->get("user") ) {
        return $c->render("login.tt", { user => $c->session->get("user") });
    }

    return $c->redirect("/checklist");
};

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;
    my $circle = $db->single(circle => { id => $args->{circle_id} });

    unless($circle) {
        return $c->create_simple_status_page(404, "Circle Not Found");
    }

    $c->render("circle.tt", { circle => $circle });
};

get '/checklist' => sub {
    my $c = shift;

    my $user = $c->session->get("user")
        or return $c->redirect("/");

    my $res = $db->search_joined(checklist => [
        circle => { 'circle.id' => 'checklist.circle_id' },
    ]);

    my $ret = {};

    while ( my @r = $res->next ) {
        my $checklist = shift @r;
        my $circle = shift @r;
        $ret->{$circle->id}->{circle} = $circle;

        push @{$ret->{$circle->id}->{favorite}}, $checklist;
    }

    return $c->render('index.tt', { user => $c->session->get('user'), res => $ret });
};

get '/logout' => sub {
    my $c = shift;
    my $user = $c->session->get("user");
    infof "LOGOUT: member_id=%s", $user->{member_id};

    $c->session->expire;
    $c->redirect("/");
};

post '/upload' => sub {
    my $c = shift;
    my $file = $c->req->upload("checklist");
    my $path = $file->path;
    my $member_id = $c->session->get('user')->{member_id};

    infof "UPLOAD_RUN: member_id=%s, file=%s", $member_id, $path;

    my $csv = Hirukara::Parser::CSV->read_from_file($path);
    #$c->render('error.tt', {}) if $csv->comiket_no ne 'ComicMarket86';

    my $result = Hirukara::Lite::Merge->new(database => $db, csv => $csv, member_id => $member_id);
    $result->run_merge;

    $c->session->set(uploaded_checklist => $result->merge_results);

    return $c->redirect("/result");
};

get "/result" => sub {
    my $c = shift;
    my $result = $c->session->get("uploaded_checklist");

    unless ($result)    {
        return $c->redirect("/checklist");
    }

    ## display result is only once
    $c->session->remove("uploaded_checklist");
    $c->render("result.tt", { result => $result });
};

#__PACKAGE__->load_plugin('Web::CSRFDefender' => { post_only => 1 });
# __PACKAGE__->load_plugin('DBI');
# __PACKAGE__->load_plugin('Web::FillInFormLite');
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

        if ( my $member = $db->single('member' => { member_id => $screen_name }) )    {
            $member->image_url($me->{profile_image_url});
            $member->update;
        } else {
            $db->insert(member => { member_id => $screen_name, image_url => $image_url });
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

__PACKAGE__->enable_session();
__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ wrapper.tt
<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <title>Hirukara::Lite</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
    <link href="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
    <script src="//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
    <link rel="stylesheet" href="[% uri_for('/static/css/main.css') %]">
</head>
<style>
* { margin: 0; padding: 0 }

table { border-collapse: collapse }

th, td { border: 1px solid black; padding: 2px 5px; font-size: 12px }

table.result tr *:nth-child(1) { width: 80px }
table.result tr *:nth-child(2) { width: 160px }
table.result tr *:nth-child(3) { width: 120px }
table.result tr *:nth-child(4) { width: 20px }
table.result tr *:nth-child(5) { width: 620px }
table.result tr:hover { background-color: #fee }

table.result.create th { background-color: #faa }
table.result.exist  th { background-color: #afa }
table.result.delete th { background-color: #aaf }

tr.color1 { background-color: #fdd }
tr.color2 { background-color: #dfd }
tr.color3 { background-color: #ddf }
tr.color4 { background-color: #ffd }
tr.color5 { background-color: #fdf }
tr.color6 { background-color: #dff }
tr.color7 { background-color: #faa }
tr.color8 { background-color: #a9a }
tr.color9 { background-color: #aa9 }

#header {
    padding: 5px;
    overflow: hidden;
    margin-bottom: 20px;
}

#header #title     {
    float: left; width: 45%;
    font-family: monospace;
    font-size: 36px;
    text-shadow: gray 3px 3px 3px;
}

#header #user_info {
    float: right;
    width: 45%;
    text-align: right;
}

img { margin-top: 7px; margin-bottom: -7px; width: 28px; height: 28px; }
#submit_checklist { border: 1px solid white; }
#submit_checklist input[type="submit"] { width: 100% } 
</style>
<body>
<div class="container">
  <div id="header">
    <div id="title">Hirukara::Lite</div>

    <div class="navbar navbar-inverse navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="brand" href="#">Hirukara::Lite</a>
          <div class="nav-collapse collapse">
            [% IF user %]
            <ul class="nav">
              <li><img src="[% user.profile_image_url %]"></li>
              <li><a>[% user.member_id %]</a></li>
              <li><a href="[% uri_for("/logout") %]">Logout</a></li>
            </ul>
            [% END %]
          </div><!--/.nav-collapse -->
        </div>
      </div>
    </div>
  </div>
[% content %]
</div>
</body>
</html>
 

@@ login.tt
[% WRAPPER 'wrapper.tt' %]
Login via <a href="[% uri_for("/auth/twitter/authenticate") %]">Twitter</a>
[% END %]


@@ circle.tt
[% WRAPPER 'wrapper.tt' %]
[% circle.id %]
[% circle.circle_name %]
[% END %]

@@ index.tt
[% WRAPPER 'wrapper.tt' %]
<form id="submit_checklist" method="POST" action="[% uri_for('/upload') %]" enctype="multipart/form-data">
<input type="file" name="checklist" />
<input type="submit" value="Send" />
</form>

<table>
[% FOREACH kv IN res.kv(); circle = kv.value.circle; f = kv.value.favorite %]
    <tr>
        <td><a href="[% uri_for("/circle/" _ circle.id) %]">[% circle.circle_name %]</td>
        <td>[% circle.circle_author %]</td>
        <td>[% f.size() %]</td>
        <td>
            [% FOREACH m IN f %]
            <div>[% m.member_id %] - [% m.comment %] at [% m.created_at %]</div>
            [% END %]
        </td>
    </tr>
[% END %]
</table>
[% END %]


@@ result.tt
[% WRAPPER 'wrapper.tt' %]
<a href="[% uri_for("/checklist") %]">Back to Checklist</a>

[% FOREACH type IN ['create', 'exist', 'delete'] %]
<h2>[% type %]</h2>
<table class="result [% type %]">
    <tr>
        <th>スペース</th>
        <th>サークル名</th>
        <th>作者</th>
        <th>色</th>
        <th>コメント</th>
    </tr>
    [% FOREACH kv IN result[type].kv(); circle = kv.value.circle; f = kv.value.favorite; %]
    <tr>
        <td>
            [% circle.day %][% circle.area %]
            [% circle.circle_sym %][% circle.circle_num %][% circle.circle_flag %]
        </td>
        <td>[% circle.circle_name %]</td>
        <td>[% circle.circle_author %]</td>
        <td>[% f.color %]</td>
        <td>[% f.comment %]</td>
    </tr>
    [% END %]
</table>
[% END %]
[% END %]

