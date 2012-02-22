package Cinnamon::Remote;
use strict;
use warnings;
use Carp ();
use Net::OpenSSH;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub connection {
    my $self = shift;
       $self->{connection} ||= Net::OpenSSH->new(
           $self->{host}, user => $self->{user}
       );
}

sub host { $_[0]->{host} }

sub execute {
    my ($self, @cmd) = @_;
    my ($stdout, $stderr) = $self->connection->capture2(join(' ', @cmd));

    Carp::croak $self->connection->error
            if  $self->connection->error;

    ($stdout, $stderr);
}

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
