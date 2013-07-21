package Cinnamon::Local;
use strict;
use warnings;

use Moo;

use IPC::Run ();

use Cinnamon::Logger;

sub execute {
    my ($self, $commands, $opts) = @_;
    my $result = IPC::Run::run $commands, \my $stdin, \my $stdout, \my $stderr;
    chomp for ($stdout, $stderr);

    for my $line (split "\n", $stdout) {
        log info => sprintf "[localhost :: stdout] %s",
            $line;
    }
    for my $line (split "\n", $stderr) {
        log info => sprintf "[localhost :: stderr] %s",
            $line;
    }

    +{
        stdout    => $stdout,
        stderr    => $stderr,
        has_error => $? > 0,
        error     => $?,
    };
}

!!1;
