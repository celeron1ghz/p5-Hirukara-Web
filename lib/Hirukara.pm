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
