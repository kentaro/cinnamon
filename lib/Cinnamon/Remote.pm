package Cinnamon::Remote;
use strict;
use warnings;
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

    +{
        stdout    => $stdout,
        stderr    => $stderr,
        has_error => !$self->connection->error,
        error     => $self->connection->error,
    };
}

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
