package Cinnamon::Config;
use strict;
use warnings;

use Coro;
use Coro::RWLock;
use Cinnamon::Config::Loader;
use Cinnamon::Logger;

my %CONFIG;
my %ROLES;
my %TASKS;

my $lock = new Coro::RWLock;

sub set ($$) {
    my ($key, $value) = @_;

    $lock->wrlock;
    $CONFIG{$key} = $value;
    $lock->unlock;
}

sub get ($@) {
    my ($key, @args) = @_;

    $lock->rdlock;
    my $value = $CONFIG{$key};
    $lock->unlock;

    $value = $value->(@args) if ref $value eq 'CODE';
    $value;
}

sub set_role ($$$) {
    my ($role, $hosts, $params) = @_;

    $lock->wrlock;
    $ROLES{$role} = [$hosts, $params];
    $lock->unlock;
}

sub get_role (@) {
    my $role  = ($_[0] || get('role'));

    my $role_def = $ROLES{$role} or return undef;

    $lock->rdlock;
    my ($hosts, $params) = @$role_def;
    $lock->unlock;

    for my $key (keys %$params) {
        set $key => $params->{$key};
    }

    $hosts = $hosts->() if ref $hosts eq 'CODE';
    $hosts = [] unless defined $hosts;
    $hosts = ref $hosts eq 'ARRAY' ? $hosts : [$hosts];

    return $hosts;
}

sub set_task ($$) {
    my ($task, $task_def) = @_;
    $lock->wrlock;
    $TASKS{$task} = $task_def;
    $lock->unlock;
}

sub get_task (@) {
    my ($task) = @_;

    $task ||= get('task');
    my @task_path = split(':', $task);

    $lock->rdlock;
    my $value = \%TASKS;
    for (@task_path) {
        $value = $value->{$_};
    }
    $lock->unlock;

    $value;
}

sub user () {
    get 'user' || do {
        my $user = qx{whoami};
        chomp $user;
        $user;
    };
}

sub load (@) {
    my ($role, $task, %opt) = @_;

    set role => $role;
    set task => $task;

    Cinnamon::Config::Loader->load(config => $opt{config});
}

!!1;
