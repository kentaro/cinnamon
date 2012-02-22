package Cinnamon::Config;
use strict;
use warnings;
use parent qw(
    Exporter
    Cinnamon::Storage
);

our @EXPORT = qw(
    set
    get
    role
    task
);

__PACKAGE__->storage({});

# user commands
sub set ($$) {
    my ($name, $value) = @_;
    __PACKAGE__->storage->{$name} = $value;
}

sub get ($) {
    my ($name) = @_;
    __PACKAGE__->storage->{$name};
}

sub role ($$) {
    my ($name, $hosts) = @_;
    __PACKAGE__->storage->{__ROLES__} ||= {};
    __PACKAGE__->storage->{__ROLES__}{$name} = ref $hosts eq 'CODE' ? $hosts :
        ref $hosts ne 'ARRAY' ? [$hosts] : $hosts;
}

sub task ($$&) {
    my ($role, $task, $code) = @_;

    __PACKAGE__->storage->{__TASKS__}{$role} ||= {};
    __PACKAGE__->storage->{__TASKS__}{$role}{$task} = $code;
}

# internal
sub hosts () {
    my ($class) = @_;
    my $role  = get('role');
    my $hosts = __PACKAGE__->storage->{__ROLES__}{$role};
       $hosts = $hosts->() if ref $hosts eq 'CODE';

    ref $hosts ne 'ARRAY' ? [$hosts] : $hosts;
}

sub get_task () {
    my ($class) = @_;
    my $role  = get 'role';
    my $task  = get 'task';

    __PACKAGE__->storage->{__TASKS__}{$role}{$task};
}

sub user () {
    __PACKAGE__->storage->{user} || do {
        my $user = qx{whoami};
        chomp $user;
        $user;
    };
}

!!1;
