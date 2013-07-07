package Cinnamon::Context;
use strict;
use warnings;

use YAML ();
use Class::Load ();

use Cinnamon::Config;
use Cinnamon::Runner;
use Cinnamon::Logger;

our $CTX;

sub new {
    my $class = shift;
    bless { }, $class;
}

sub run {
    my ($self, $role, $task, %opts)  = @_;
    my @args     = Cinnamon::Config::load $role, $task, %opts;

    if ($opts{info}) {
        log 'info', YAML::Dump(Cinnamon::Config::info);
        return;
    }

    my $hosts    = Cinnamon::Config::get_role;
    my $task_def = Cinnamon::Config::get_task;
    my $runner   = Cinnamon::Config::get('runner_class') || 'Cinnamon::Runner';

    unless (defined $hosts) {
        log 'error', "undefined role : '$role'";
        return;
    }
    unless (defined $task_def) {
        log 'error', "undefined task : '$task'";
        return;
    }

    Class::Load::load_class $runner;

    my $result = $runner->start($hosts, $task_def);
    my (@success, @error);

    for my $key (keys %{$result || {}}) {
        if ($result->{$key}->{error}) {
            push @error, $key;
        }
        else {
            push @success, $key;
        }
    }

    log success => sprintf(
        "\n========================\n[success]: %s",
        (join(', ', @success) || ''),
    );

    log error => sprintf(
        "[error]: %s",
        (join(', ', @error)   || ''),
    );

    return (\@success, \@error);
}

!!1;
