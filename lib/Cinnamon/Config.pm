package Cinnamon::Config;
use strict;
use warnings;

use Cinnamon::Config::Loader;
use Cinnamon::Logger;

my %CONFIG;
my %ROLES;
my %TASKS;

sub set ($$) {
    my ($key, $value) = @_;

    $CONFIG{$key} = $value;
}

sub get ($@) {
    my ($key, @args) = @_;

    my $value = $CONFIG{$key};

    $value = $value->(@args) if ref $value eq 'CODE';
    $value;
}

sub set_role ($$$) {
    my ($role, $hosts, $params) = @_;

    $ROLES{$role} = [$hosts, $params];
}

sub get_role (@) {
    my $role  = ($_[0] || get('role'));

    my $role_def = $ROLES{$role} or return undef;

    my ($hosts, $params) = @$role_def;

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
    $TASKS{$task} = $task_def;
}

sub get_task (@) {
    my ($task) = @_;

    $task ||= get('task');
    my @task_path = split(':', $task);

    my $value = \%TASKS;
    for (@task_path) {
        $value = $value->{$_};
    }

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
