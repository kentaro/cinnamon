package Cinnamon::Runner;
use strict;
use warnings;

use Coro;

use Cinnamon::Logger;
use Cinnamon::Config;

sub start {
    my ($class, $hosts, @args) = @_;
    my $task        = Cinnamon::Config::get_task;
    my $concurrency = Cinnamon::Config::get('concurrency') || 1;

    my %result;
    my @workers;
    for my $job (@{$hosts || []}) {
        my $i = scalar(@$hosts) % $concurrency;

        $workers[$i] ||= [];
        push @{$workers[$i]}, $job;

        $result{$job} = +{ error => 0 };
    }

    my @coros;
    for my $jobs (@workers) {
        push @coros, async {
            for my $job (@$jobs) {
                eval { $task->($job, @args) };

                if ($@) {
                    chomp $@;
                    log error => sprintf '[%s] %s', $job, $@;
                    $result{$job}->{error}++ ;
                }
            }
        };
    }

    $_->join for @coros;
    \%result;
}

sub execute {
    my ($class, $host, $task, @args) = @_;
    $task->($host, @args);
}

!!1;
