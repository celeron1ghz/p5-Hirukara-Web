package Hirukara::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::RouterBoom;

use Log::Minimal;
use Encode;

## auth
get '/' => sub {
    my $c = shift;
    $c->loggin_user
        ? $c->render("notice.tt", { notice => $c->run_command('notice.select') })
        : $c->render("login.tt");
};

get '/logout' => sub {
    my $c = shift;
    my $user = $c->session->get("user");
    infof "LOGOUT: member_id=%s", $user->{member_id};
    $c->session->expire;
    $c->redirect("/");
};

## searching
get '/search' => sub {
    my $c = shift;
    my $cond = $c->get_condition_object($c->req);
    my $ret;

    if (my $where = $cond->{condition}) {
        $ret = $c->run_command('circle.search' => { where => $where });
    }

    $c->fillin_form($c->req);
    $c->render("search.tt", {
        res => $ret,
        conditions => $cond->{condition_label},
        condition => $cond->{condition},
    });
};

get '/search/checklist' => sub {
    my $c = shift;
    my $user = $c->loggin_user;
    my $cond = $c->get_condition_object($c->req);
    my $assigns = $c->run_command('assign.search');

    my $where = $cond->{condition};
    my $ret   = $c->db->search_all_joined($where);

    $c->fillin_form($c->req);

    return $c->render('search/checklist.tt', {
        res        => $ret,
        conditions => $cond->{condition_label},
        assigns    => $assigns,
    });
};

get '/search/circle_type/{id}' => sub {
    my($c,$args) = @_;
    my $type = $c->db->single(circle_type => { id => $args->{id} }) or return $c->res_404;
    my $ret  = $c->run_command('search.by_circle_type', { id => $type->id });
    $c->render('search/circle_type.tt', { circles => $ret, type => $type });
};

## circle
post '/circle/update' => sub {
    my($c,$args) = @_;
    my $id = $c->request->param("circle_id");

    $c->run_command('circle.update' => {
        member_id   => $c->loggin_user->{member_id},
        circle_id   => $id,
        circle_type => $c->request->param("circle_type"),
        comment     => $c->request->param("circle_comment"),
    });

    $c->redirect("/circle/$id");
};

get '/circle/{circle_id}' => sub {
    my($c,$args) = @_;
    my $circle = $c->run_command('circle.single' => { circle_id => $args->{circle_id} })
        or return $c->create_simple_status_page(404, "Circle Not Found");

    my $it = $c->run_command('checklist.search' => { where => { "circle_id" => $circle->id } });
    my @chk;
    for my $row ($it->all) {
        push @chk, $row;
    }

    my $my = $c->run_command('checklist.single' => { circle_id => $circle->id, member_id => $c->loggin_user->{member_id} });

    $c->fillin_form({
        circle_type       => $circle->circle_type,
        circle_comment    => $circle->comment,
        checklist_comment => $my ? $my->comment : "",
        order_count       => $my ? $my->count : 0,
    });

    $c->render("circle.tt", {
        circle    => $circle,
        checklist => \@chk,
    });
};

## checklist
post '/checklist/add' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->run_command('checklist.create' => { member_id => $member_id, circle_id => $circle_id });
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");
    $c->run_command('checklist.delete' => { member_id => $member_id, circle_id => $circle_id });
    $c->redirect("/circle/$circle_id");
};

post '/checklist/delete_all' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    $c->run_command('checklist.delete_all' => { member_id => $member_id });
    $c->redirect("/member/$member_id");
};

post '/checklist/update' => sub {
    my($c) = @_;
    my $member_id = $c->loggin_user->{member_id};
    my $circle_id = $c->request->param("circle_id");

    $c->run_command('checklist.update' => {
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

    $c->run_command('checklist.bulk_operation' => {
        member_id => $member_id,
        create_chk_ids => \@create,
        delete_chk_ids => \@delete,
    });

    $c->redirect("/search/checklist?member_id=$member_id");
};

post '/upload' => sub {
    my $c = shift;
    my $file = $c->req->upload("checklist")
        or return $c->create_simple_status_page(403, "Please upload a file");

    my $member_id = $c->session->get('user')->{member_id};
    my $path = $file->path;
    my $dest = $c->checklist_dir->child(sprintf "%s_%s.csv", time, $member_id);

    #copy $path, $dest;
    infof "UPLOAD_RUN: member_id=%s, file=%s, copy_to=%s", $member_id, $path, $dest;

    my $result = $c->run_command('checklist.parse' => { csv_file => $path, member_id => $member_id });
    $c->render("result.tt", { result => $result->merge_results });
};

get "/export/{output_type}" => sub {
    my($c,$args) = @_;
    my $user = $c->loggin_user;
    my $type = $args->{output_type};

    my $ret = $c->run_command('checklist.export', {
        where     => $c->req->parameters,
        type      => $type,
        member_id => $c->loggin_user->{member_id},
        template_var => {
            member_id => $user->{member_id},
        },
    });

    my $filename = encode_utf8 sprintf "%s_%s.%s", $c->exhibition, time, $ret->{extension};
    my @header = ("content-disposition", sprintf "attachment; filename=$filename");

    close $ret->{file};
    open my $fh, $ret->{file} or die;
    $c->create_response(200, \@header, $fh);
};

## statistics page
get '/member/{member_id}' => sub {
    my($c,$args) = @_;
    my $m = $c->run_command('member.select' => { member_id => $args->{member_id} }) or return $c->res_404;
    $c->render("member.tt", {
        member => $m,
        counts => $c->run_command('statistic.single' => { member_id => $m->member_id }),
        assign => [$c->run_command('assign.search'   => { member_id => $m->member_id })->all],
    });
};

get '/members' => sub {
    my $c = shift;
    $c->render("members.tt", { statistics => $c->run_command('statistic.select') });
};


## admin page
get "/admin/log" => sub {
    my $c = shift;
    $c->render("admin/log.tt", { logs => $c->run_command('action_log.select', { page => $c->req->param("page") || 0 }) });
};

get '/admin/notice' => sub {
    my $c = shift;
    my $key = $c->req->param("key");
    my $notice;

    if ($key)   {
        $notice = $c->run_command('notice.single', { key => $key });

        if (@$notice)   {
            $c->fillin_form($notice->[0]->get_columns);
        }
    }

    $c->render("admin/notice.tt", {
        noticies => $c->run_command('notice.select'),
        $key ? (notice => $notice) : (),
    });
};

post '/admin/notice' => sub {
    my $c = shift;
    $c->run_command('notice.update' => {
        key   => $c->req->param("key"),
        title => $c->req->param("title"),
        text  => $c->req->param("text"),
        member_id => $c->loggin_user->{member_id},
    });
    $c->redirect("/admin/notice");
};

get '/admin/assign' => sub {
    my $c = shift;
    my $assign = $c->run_command('assign.search');
    $c->render('admin/assign_list.tt', { assign => $assign });
};

get '/admin/assign/view'   => sub {
    my $c = shift;
    my $cond = $c->get_condition_object($c->req);
    my $ret;

    if (my $where = $cond->{condition}) {
        $ret = $c->run_command('checklist.joined' => { where => $cond->{condition} });
    }

    $c->fillin_form($c->req);
    my $assign = $c->run_command('assign.search');

    return $c->render('admin/assign.tt', {
        res => $ret,
        assign => $assign,
        conditions => $cond->{condition_label},
        condition => $cond->{condition},
    });
};

post '/admin/assign/create'   => sub {
    my $c = shift;
    my $no = $c->request->param("comiket_no");
    $c->run_command('assign_list.create', { member_id => $c->loggin_user->{member_id} });
    $c->redirect("/admin/assign");
};

post '/admin/assign/update'   => sub {
    my $c = shift;

    $c->run_command('assign.create' => {
        assign_list_id  => $c->request->param("assign_id"),
        circle_ids => [ $c->request->param("circle") ],
    });

use URI;
    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/admin/assign/view?$param");
};

post '/admin/assign/delete'   => sub {
    my $c = shift;
    my $id = $c->request->param("assign_list_id");
    $c->run_command('assign_list.delete', { assign_list_id => $id, member_id => $c->loggin_user->{member_id} });
    $c->redirect("/admin/assign");
};

post '/admin/assign_info/delete'   => sub {
    my $c = shift;
    my $id = $c->request->param("assign_id");
    $c->run_command('assign.delete' => { id => $id, member_id => $c->loggin_user->{member_id} });
    my $uri = URI->new($c->req->header("Referer"));
    my $param = $uri->query;
    $c->redirect("/admin/assign/view?$param");
};

post '/admin/assign_info/update'   => sub {
    my $c = shift;
    my $assign_id = $c->request->param("assign_id");
    my $assign = $c->db->single(assign_list => { id => $assign_id });

    $c->run_command('assign_list.update' => {
        assign_id        => $assign_id,
        assign_member_id => $c->request->param("assign_member"),
        assign_name      => $c->request->param("assign_name"),
        member_id        => $c->loggin_user->{member_id},
    });

    $c->redirect("/admin/assign");
};

get '/admin/assign_info/download'   => sub {
    my $c        = shift;
    my $tempfile = $c->run_command('checklist.bulkexport', { member_id => $c->loggin_user->{member_id} });
    my $filename = sprintf "%s.zip", $c->exhibition;
    my @headers  = ("content-disposition", "attachment; filename=$filename");

    open my $fh, $tempfile or die "$tempfile: $!";
    return $c->create_response(200, \@headers, $fh);
};

get '/admin/circle_type' => sub {
    my $c = shift;
    my $types = $c->run_command('circle_type.search');
    $c->render('admin/circle_type.tt', { types => $types });
};

post '/admin/circle_type/create' => sub {
    my $c = shift;
    $c->run_command('circle_type.create' => {
        type_name => '新規属性',
        comment   => '',
        scheme    => 'info',
    });
    $c->redirect('/admin/circle_type');
};

post '/admin/circle_type/update' => sub {
    my $c = shift;
    $c->run_command('circle_type.update' => {
        id        => $c->req->param('id'),
        type_name => $c->req->param('name'),
        comment   => $c->req->param('comment'),
    });
    $c->redirect('/admin/circle_type');
};

1;
