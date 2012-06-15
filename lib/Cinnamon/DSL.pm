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
    desc

    remote
    run
    sudo
);

my $cur_desc = '';

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

sub desc ($) {
    my ($desc) = @_;
    $cur_desc = $desc;
}

sub task ($$) {
    my ($task, $task_def) = @_;

    if($cur_desc) {
        Cinnamon::Config::set_desc $task => $cur_desc;
        $cur_desc = "";
    }
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
    my $result;

    my $is_remote = ref $_ eq 'Cinnamon::Remote';
    my $host = $is_remote ? $_->host : 'localhost';

    log info => sprintf "[%s :: executing] %s", $host, join(' ', @cmd);

    if (ref $_ eq 'Cinnamon::Remote') {
        $result = $_->execute($opt, @cmd);
    }
    else {
        $result = Cinnamon::Local->execute(@cmd);
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
        ReadMode 0;
        print "\n";
    }

    run {sudo => 1, password => $password}, @cmd;
}

!!1;
