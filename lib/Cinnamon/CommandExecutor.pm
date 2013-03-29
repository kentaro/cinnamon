package Cinnamon::CommandExecutor;
use strict;
use warnings;
use Carp ();

use Cinnamon::CommandBuilder;
use Cinnamon::HandleManager;

sub new {
    my ($class, %args) = @_;
    Carp::croak __PACKAGE__ . " can't be instantiated" if ($class eq __PACKAGE__);
    bless \%args, $class;
}

sub host     { Carp::croak "host() is not implemented" }
sub _execute { Carp::croak "actually_execute() is not implemented" }

sub execute {
    my ($self, $opt, @cmd) = @_;
    $opt ||= {};

    my $builder = Cinnamon::CommandBuilder->new(%$opt);
    if (defined $opt->{password}) {
        push @{ $builder->{sudo_opts} }, '-p', '';
    }
    @cmd = $builder->build(@cmd);

    my $hm = Cinnamon::HandleManager->new(host => $self->host);
    my ( $stdout, $stderr, $exitcode )
        = $hm->handle( sub { $self->_execute( $opt, @cmd ) } );

    +{
        stdout    => $stdout,
        stderr    => $stderr,
        has_error => $exitcode > 0,
        error     => $exitcode,
    };
}

!!1;
