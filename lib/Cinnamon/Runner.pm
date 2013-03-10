package Cinnamon::Runner;
use strict;
use warnings;

use Cinnamon::Logger;
use Cinnamon::Config;

sub start {
    my ($class, $hosts, $task, $role, @args) = @_;

    my %result;
    for my $host (@$hosts) {
        $result{$host} = +{ error => 0 };

        eval { $task->($host, $role, @args) };

        if ($@) {
            chomp $@;
            log error => sprintf '[%s] %s', $host, $@;
            $result{$host}->{error}++ ;
        }
    }

    \%result;
}

sub execute {
    my ($class, $host, $role, $task, @args) = @_;
    $task->($host, $role, @args);
}

!!1;
