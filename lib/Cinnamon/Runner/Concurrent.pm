package Cinnamon::Runner::Concurrent;
use strict;
use warnings;

use Cinnamon::Logger;
use Cinnamon::Config;

use Coro;
use Coro::Select;

sub start {
    my ($class, $hosts, $task, @args) = @_;
    my @coros;
    my $all_results = {};

    for my $host (@$hosts) {
        my $coro = async {
            my $result = $class->execute($host, $task, @args);
            $all_results->{$host} = $result;
        };

        push @coros, $coro;
    }

    $_->join for @coros;

    return $all_results;
}

sub execute {
    my ($class, $host, $task, @args) = @_;

    my $result = { host => $host, error => 0 };

    local $@;
    eval { $task->($host, @args) };
    if ($@) {
        chomp $@;
        log error => sprintf '[%s] %s', $host, $@;
        $result->{error} = 1;
    }

    return $result;
}

1;
