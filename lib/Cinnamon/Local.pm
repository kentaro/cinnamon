package Cinnamon::Local;
use strict;
use warnings;
use Carp ();
use IPC::Run ();

use base qw/Cinnamon::CommandExecutor/;

sub host { 'localhost' }

sub _execute {
    my ($self, $opt, @cmd) = @_;

    my $stdin_str;
    if (defined $opt->{password}) {
        $stdin_str = "$opt->{password}\n";
    }

    IPC::Run::run \@cmd, \$stdin_str or die;
}

!!1;
