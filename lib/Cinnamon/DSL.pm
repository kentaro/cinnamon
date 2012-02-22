package Cinnamon::DSL;
use strict;
use warnings;
use parent qw(Exporter);

use Cinnamon::Config;
use Cinnamon::Local;
use Cinnamon::Remote;
use Cinnamon::Logger;

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
    my $value = Cinnamon::Config::get $name;
       $value = $value->(@args) if ref $value eq 'CODE';
       $value;
}

sub role ($$) {
    my ($name, $hosts) = @_;
    Cinnamon::Config::set_role $name => $hosts;
}

sub task ($%) {
    my ($role, $tasks) = @_;

    for my $task (%$tasks) {
        Cinnamon::Config::set_task $role => $task => $tasks->{$task};
    }
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
    my ($stdout, $stderr);
    my $host;

    if (ref $_ eq 'Cinnamon::Remote') {
        $host = $_->host;
        ($stdout, $stderr) = eval { $_->execute(@cmd) };
    }
    else {
        $host = 'localhost';
        ($stdout, $stderr) = eval { Cinnamon::Local->execute(@cmd) };
    }

    if ($@) {
        my $message = sprintf "[%s] %s\n%s", $host, $@, join(' ', @cmd);
        log error => $message;
        exit 1;
    }
    else {
        my $message = sprintf "[%s] %s", $host, join(' ', @cmd);
        log info => $message;
    }

    if ($stdout) {
        chomp $stdout;
        print "  STDOUT: $stdout\n";
    }
    if ($stderr) {
        chomp $stderr;
        print "  STDERR: $stderr\n";
    }

    ($stdout, $stderr);
}

sub sudo (@) {
    my (@cmd) = @_;
    run 'sudo', @cmd;
}

!!1;
