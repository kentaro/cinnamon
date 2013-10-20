package Cinnamon::Runner;
use strict;
use warnings;

use Cinnamon qw(CTX);
use Cinnamon::Logger;

use Coro;
use Coro::Select;

sub start {
    my ($class, $hosts, $task) = @_;
    my $all_results = {};
    $hosts = [ @$hosts ];

    my $task_name           = $task->name;
    my $concurrency_setting = CTX->get_param('concurrency') || {};
    my $concurrency         = $concurrency_setting->{$task_name} || scalar @$hosts;

    while (my @target_hosts = splice @$hosts, 0, $concurrency) {
        my @coros;

        for my $host (@target_hosts) {
            my $coro = async {
                my $result = $class->execute($host, $task);
                $all_results->{$host} = $result;
            };

            push @coros, $coro;
        }

        $_->join for @coros;
    }

    return $all_results;
}

sub execute {
    my ($class, $host, $task) = @_;

    my $result = { host => $host, error => 0 };

    local $@;
    eval { $task->execute($host) };
    if ($@) {
        chomp $@;
        log error => sprintf '[%s] %s', $host, $@;
        $result->{error} = 1;
    }

    return $result;
}

1;
