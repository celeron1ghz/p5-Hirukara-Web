package Hirukara;
use Mouse;
use Hirukara::Database;
use Hirukara::Util;
use Hirukara::Merge;
use Hirukara::Parser::CSV;
use Hirukara::Export::ComiketCsv;
use Hirukara::Export::Excel;
use Hirukara::Constants::CircleType;
use Log::Minimal;
use JSON;
use Smart::Args;
use Module::Load();

has database => ( is => 'ro', isa => 'Teng', required => 1 );

sub load    {
    my($class,$conf) = @_; 

    my $db_conf = $conf->{database} or die "key 'database' missing";
    my $db = Hirukara::Database->load($db_conf);

    $class->new({ database => $db }); 
}


### assign methods
sub get_assign_lists {
    my($self,$cond) = @_;
    [$self->database->search("assign_list", $cond)->all];
}

sub get_assign_lists_with_count {
    my $self = shift;
    my $assign = $self->database->search_by_sql(<<SQL);
SELECT assign_list.*, COUNT(assign.id) AS count FROM assign_list
    LEFT JOIN assign ON assign_list.id = assign.assign_list_id
    GROUP BY assign_list.id
SQL

    [$assign->all];
}

sub create_assign_list  {
    args my $self,
         my $comiket_no => { isa => 'Str' };

    my $ret = $self->database->insert(assign_list => { name => "新規作成リスト", member_id => undef, comiket_no => $comiket_no });
    infof "CREATE_ASSIGN_LIST: id=%s, name=%s, comiket_no=%s", $ret->id, $ret->name, $ret->comiket_no;

    $ret;
}

sub update_assign_list  {
    args my $self,
         my $member_id     => { isa => 'Str' },
         my $assign_id     => { isa => 'Str' },
         my $assign_member => { isa => 'Str' },
         my $assign_name   => { isa => 'Str' };

    my $assign = $self->database->single(assign_list => { id => $assign_id });
    my $member_updated;
    my $name_updated;

    if ($assign_member ne $assign->member_id) {
        my $before_assign_member = $assign->member_id;;
        $assign->member_id($assign_member);
        $member_updated++;
        infof "UPDATE_ASSIGN_MEMBER: assign_id=%s, updated_by=%s, before_member=%s, updated_name=%s", $assign->id, $member_id, $before_assign_member, $assign_member;

        $self->__create_action_log(ASSIGN_MEMBER_UPDATE => {
            updated_by     => $member_id,
            assign_id      => $assign->id,
            before_member  => $before_assign_member,
            updated_member => $assign_member,
        });
    }
    
    if ($assign_name ne $assign->name)   {
        my $before_name = $assign->name;
        $assign->name($assign_name);
        $name_updated++;
        infof "UPDATE_ASSIGN_NAME: assign_id=%s, updated_by=%s, before_name=%s, updated_name=%s", $assign->id, $member_id, $before_name, $assign_name;

        $self->__create_action_log(ASSIGN_NAME_UPDATE => {
            updated_by   => $member_id,
            assign_id    => $assign->id,
            before_name  => $before_name,
            updated_name => $assign_name,
        });
    }

    $assign->update if $member_updated or $name_updated;
}


### action log methods
sub __create_action_log   {
    my($self,$messid,$param) = @_;
    my $circle_id = $param->{circle_id};

    $self->database->insert(action_log => {
        message_id  => $messid,
        circle_id   => $circle_id,
        parameters  => encode_json $param,
    });
}

### notice methods
sub get_notice  {
    my $self = shift;
    $self->database->single('notice' => { id => \'= (SELECT MAX(id) FROM notice)' });
}

sub update_notice   {
    args my $self,
         my $member_id => { isa => 'Str' },
         my $text      => { isa => 'Str' };

    infof "UPDATE_NOTICE: member_id=%s", $member_id;
    $self->database->insert(notice => {
        member_id => $member_id,
        text      => $text,
    }); 
}

### other methods
sub merge_checklist {
    my($self,$csv,$member_id) = @_;
    my $ret = Hirukara::Merge->new(database => $self->database, csv => $csv, member_id => $member_id);

    $self->__create_action_log(CHECKLIST_MERGE => {
        member_id   => $member_id,
        create      => (scalar keys %{$ret->merge_results->{create}}),
        delete      => (scalar keys %{$ret->merge_results->{delete}}),
        exist       => (scalar keys %{$ret->merge_results->{exist}}),
        comiket_no  => $csv->comiket_no,
    });

    $ret;
}

sub parse_csv   {
    my($self,$path) = @_;
    my $ret = Hirukara::Parser::CSV->read_from_file($path);
    $ret;
}

sub checklist_export_as   {
    my($class,$type,$checklists,@args) = @_;
    my $load_class = sprintf "Hirukara::Export::%s", $type;

    Module::Load::load $load_class;
    $load_class->new(checklists => $checklists, @args);
}

sub assign_export_as   {
    my($class,$type,$checklists,@args) = @_;
    my $load_class = sprintf "Hirukara::Export::%s", $type;

    Module::Load::load $load_class;
    $load_class->new(checklists => $checklists, @args);
}

1;
