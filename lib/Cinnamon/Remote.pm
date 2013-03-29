package Cinnamon::Remote;
use strict;
use warnings;
use Net::OpenSSH;

use base qw/Cinnamon::CommandExecutor/;

sub connection {
    my $self = shift;
    return Net::OpenSSH->new(
        $self->{host}, user => $self->{user},
    );
}

sub host { $_[0]->{host} || '' }

sub _execute {
    my ($self, $opt, @cmd) = @_;

    my $stdin_str;
    if (defined $opt->{password}) {
        $stdin_str = "$opt->{password}\n";
    }

    $self->connection->system(
        { stdin_data => $stdin_str, tty => $opt->{tty} },
        @cmd,
    ) or die;
}

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
