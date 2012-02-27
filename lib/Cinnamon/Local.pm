package Cinnamon::Local;
use strict;
use warnings;
use Carp ();
use IPC::Run ();

sub execute {
    my ($class, @cmd) = @_;
    my $result = IPC::Run::run \@cmd, \my $stdin, \my $stdout, \my $stderr;
    chomp for ($stdout, $stderr);

    +{
        stdout    => $stdout,
        stderr    => $stderr,
        has_error => !$result,
        error     => $?,
    };
}

!!1;
