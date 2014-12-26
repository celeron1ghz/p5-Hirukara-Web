package Hirukara::Command::Checklist::Export;
use Mouse;
use Module::Load;

with 'MouseX::Getopt', 'Hirukara::Command';

has type         => ( is => 'ro', isa => 'Str', required => 1 );
has split_by     => ( is => 'ro', isa => 'Str', required => 1 );
has checklists   => ( is => 'ro', isa => 'ArrayRef', required => 1 );
has template_var => ( is => 'ro', isa => 'HashRef', required => 1 );

my %EXPORT_TYPE = ( 
    checklist => "ComiketCsv",
    excel     => "Excel",
    pdf       => "PDF",
);

sub run {
    my $self = shift;
    my $type = $EXPORT_TYPE{$self->type} or die "unknown type " . $self->type;
    my $load_class = sprintf "Hirukara::Export::%s", $type;

    Module::Load::load $load_class;
    my $obj = $load_class->new(checklists => $self->checklists, split_by => $self->split_by, template_var => $self->template_var);

    $self->action_log([ type => $type, split_by => $self->split_by, file => $obj->file->filename ]);
    $obj->process;
    $obj;
}

1;
