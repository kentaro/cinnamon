package Cinnamon::DSL;
use strict;
use warnings;
use parent qw(Exporter);

use Cinnamon::Config;
use Cinnamon::Local;
use Cinnamon::Remote;
use Cinnamon::Logger;
use Term::ReadKey;

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
    Cinnamon::Config::set $name => $value;
}

sub get ($@) {
    my ($name, @args) = @_;
    Cinnamon::Config::get $name, @args;
}

sub role ($$;$) {
    my ($name, $hosts, $params) = @_;
    $params ||= {};
    Cinnamon::Config::set_role $name => $hosts, $params;
}

sub task ($$) {
    my ($task, $task_def) = @_;

    Cinnamon::Config::set_task $task => $task_def;
}

sub remote (&$) {
    my ($code, $host) = @_;

    local $_ = Cinnamon::Remote->new(
        host => $host,
        user => Cinnamon::Config::user,
    );

    $code->($host);
}

sub run (@) {
    my (@cmd) = @_;
    my $opt;
    $opt = shift @cmd if ref $cmd[0] eq 'HASH';

    my ($stdout, $stderr);
    my $host;
    my $result;

    if (ref $_ eq 'Cinnamon::Remote') {
        $host   = $_->host;
        $result = $_->execute($opt, @cmd);
    }
    else {
        $host   = 'localhost';
        $result = Cinnamon::Local->execute(@cmd);
    }

    if ($result->{has_error}) {
        my $message = sprintf "%s: %s", $host, $result->{stderr}, join(' ', @cmd);
        die $message;
    }
    else {
        my $message = sprintf "[%s] %s: %s",
            $host, join(' ', @cmd), ($result->{stdout} || $result->{stderr});

        log info => $message;
    }

    return ($result->{stdout}, $result->{stderr});
}

sub sudo (@) {
    my (@cmd) = @_;

    my $password = Cinnamon::Config::get('password');
    unless (defined $password) {
        print "Enter sudo password: ";
        ReadMode "noecho";
        chomp($password = ReadLine 0);
        Cinnamon::Config::set('password' => $password);
    }

    run {sudo => 1, password => $password}, @cmd;
}

!!1;
