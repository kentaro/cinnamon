package Cinnamon::DSL;
use strict;
use warnings;
use parent qw(Exporter);

use Cinnamon qw(CTX);
use Cinnamon::Local;
use Cinnamon::Remote;

our @EXPORT = qw(
    set
    get
    role
    task
    call

    remote
    run
    sudo
);

sub set ($$) {
    my ($name, $value) = @_;
    CTX->set_param($name => $value);
}

sub get ($@) {
    my ($name, @args) = @_;
    CTX->get_param($name, @args);
}

sub role ($$;$) {
    my ($name, $hosts, $params) = @_;
    CTX->add_role($name, $hosts, $params);
}

sub task ($$) {
    my ($task, $task_def) = @_;
    CTX->add_task($task => $task_def);
}

sub remote (&$) {
    my ($code, $host) = @_;

    my $remote = Cinnamon::Remote->new(
        host => $host,
        user => CTX->get_param('user'),
    );

    my $stash = CTX->stash;
    local $stash->{current_host}   = $remote->host;
    local $stash->{current_remote} = $remote;

    $code->($host);
}

sub call ($$) {
    my ($task_name, $host) = @_;
    CTX->call_task($task_name, $host);
}

sub run (@) {
    my (@cmd) = @_;
    return CTX->run_cmd(\@cmd);
}

sub sudo (@) {
    my (@cmd) = @_;
    return CTX->run_cmd(\@cmd, { sudo => 1 });
}

!!1;
