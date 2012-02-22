package Cinnamon::Local;
use strict;
use warnings;
use Carp ();
use IPC::Run ();

sub execute {
    my ($class, @cmd) = @_;
    my $result = IPC::Run::run \@cmd, undef, \my $stdout, \my $stderr;

    Carp::croak $? if !$result;

    ($stdout, $stderr);
}

!!1;
