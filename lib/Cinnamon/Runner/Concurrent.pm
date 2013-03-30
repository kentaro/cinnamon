package Cinnamon::Runner::Concurrent;
use strict;
use warnings;

use Parallel::ForkManager;

use Cinnamon::Logger;
use Cinnamon::Config;

sub start {
    my ($class, $hosts, $task, @args) = @_;

    my $concurrency = scalar @$hosts;
    my $pm = Parallel::ForkManager->new($concurrency);
    my $all_results = {};

    # result handling
    $pm->run_on_finish(sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
        my $host  = $data->{host};
        my $error = $data->{error};
        $all_results->{$host} = { error => $error };
    });

    for my $host (@$hosts) {
        my $pid = $pm->start and next;

        my $result = $class->execute($host, $task, @args);

        $pm->finish(0, $result);
    }

    $pm->wait_all_children;

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
