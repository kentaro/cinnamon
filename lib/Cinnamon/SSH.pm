package Cinnamon::SSH;
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

sub error {
    $_[0]->connection->error;
}

sub execute {
    my ($self, @cmd) = @_;
    my ($stdout, $stderr) = $self->connection->capture2(join(' ', @cmd));

    ($stdout, $stderr);
}

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
