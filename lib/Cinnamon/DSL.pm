package Cinnamon::DSL;
use strict;
use warnings;
use parent qw(Exporter);

use Cinnamon qw(CTX);
use Cinnamon::Local;
use Cinnamon::Remote;
use Cinnamon::Logger;
use Term::ReadKey;

use Coro;

our @EXPORT = qw(
    set
    get
    role
    task

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

sub run (@) {
    my (@cmd) = @_;
    my $opt;
    $opt = shift @cmd if ref $cmd[0] eq 'HASH';

    my ($stdout, $stderr);
    my $result;

    my $current_host = CTX->stash->{current_host} || 'localhost';
    log info => sprintf "[%s :: executing] %s", $current_host, join(' ', @cmd);

    if ($opt && $opt->{sudo}) {
        my $password = CTX->get_param('password');
        $password = _sudo_password() unless (defined $password);
        $opt->{password} = $password;
    }

    if (my $remote = CTX->stash->{current_remote}) {
        $result = $remote->execute($opt, @cmd);
    }
    else {
        $result = Cinnamon::Local->execute($opt, @cmd);
    }

    if ($result->{has_error}) {
        die sprintf "error status: %d", $result->{error};
    }

    return ($result->{stdout}, $result->{stderr});
}

sub sudo (@) {
    my (@cmd) = @_;
    my $tty = CTX->get_param('tty');
    run {sudo => 1, tty => !! $tty}, @cmd;
}

sub _sudo_password {
    my $password;
    print "Enter sudo password: ";
    ReadMode "noecho";
    chomp($password = ReadLine 0);
    CTX->set_param(password => $password);
    ReadMode 0;
    print "\n";
    return $password;
}

!!1;
