package Cinnamon::Config;
use strict;
use warnings;

use Coro;
use Coro::RWLock;
use Cinnamon::Config::Loader;

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

sub set_role ($$) {
    my ($role, $hosts) = @_;

    $lock->wrlock;
    $ROLES{$role} = $hosts;
    $lock->unlock;
}

sub get_role (@) {
    my $role  = ($_[0] || get('role')) or die "no role";

    $lock->rdlock;
    my $hosts = $ROLES{$role};
    $lock->unlock;

    $hosts = $hosts->() if ref $hosts eq 'CODE';
    ref $hosts eq 'ARRAY' ? $hosts : [$hosts];
}

sub set_task ($$$) {
    my ($role, $task, $code) = @_;
    $TASKS{$role} ||= {};

    $lock->wrlock;
    $TASKS{$role}->{$task} = $code;
    $lock->unlock;
}

sub get_task (@) {
    my ($role, $task) = @_;

    $role ||= get('role') or die "no role";
    $task ||= get('task') or die "no task";

    $lock->rdlock;
    my $value = $TASKS{$role}->{$task};
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
    my ($role, $task) = (shift, shift);

    set role => $role;
    set task => $task;

    Cinnamon::Config::Loader->load(@_);
}

!!1;
