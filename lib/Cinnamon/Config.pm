package Cinnamon::Config;
use strict;
use warnings;

my %CONFIG;
my %ROLES;
my %TASKS;

sub set ($$) {
    my ($key, $value) = @_;
    $CONFIG{$key} = $value;
}

sub get ($) {
    my ($key) = @_;
    $CONFIG{$key};
}

sub set_role ($$) {
    my ($role, $hosts) = @_;
    $ROLES{$role} = $hosts;
}

sub get_role (@) {
    my $role  = ($_[0] || get 'role') or die "no role";
    my $hosts = $ROLES{$role};
       $hosts = $hosts->() if ref $hosts eq 'CODE';

    ref $hosts eq 'ARRAY' ? $hosts : [$hosts];
}

sub set_task ($$$) {
    my ($role, $task, $code) = @_;
    $TASKS{$role} ||= {};
    $TASKS{$role}->{$task} = $code;
}

sub get_task (@) {
    my ($role, $task) = @_;

    $role ||= get 'role' or die "no role";
    $task ||= get 'task' or die "no task";

    $TASKS{$role}->{$task};
}

sub user () {
    get 'user' || do {
        my $user = qx{whoami};
        chomp $user;
        $user;
    };
}

!!1;
