package Cinnamon::DSL;
use strict;
use warnings;
use parent qw(Exporter);

use Cinnamon::Config;
use Cinnamon::Local;
use Cinnamon::Remote;
use Cinnamon::Logger;
use Cinnamon::CommandBuilder;
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

    my $remote = Cinnamon::Remote->new(
        host => $host,
        user => Cinnamon::Config::user,
    );

    no warnings 'redefine';
    local *_host    = sub { $remote->host };
    local *_execute = sub { $remote->execute(@_) };

    $code->($host);
}

sub run (@) {
    my (@cmd) = @_;
    my $opt = (ref $cmd[0] eq 'HASH') ? shift @cmd : {};

    my ($stdout, $stderr);
    my $result;

    my $cmd_str = Cinnamon::CommandBuilder->new(%$opt)->build(@cmd);
    log info => sprintf "[%s :: executing] %s", _host(), $cmd_str;

    if ($opt && $opt->{sudo}) {
        my $password = Cinnamon::Config::get('password');
        $password = _sudo_password() unless (defined $password);
        $opt->{password} = $password;
    }

    $result = _execute($opt, @cmd);

    if ($result->{has_error}) {
        die sprintf "error status: %d", $result->{error};
    }

    return ($result->{stdout}, $result->{stderr});
}

sub sudo (@) {
    my (@cmd) = @_;
    my $tty = Cinnamon::Config::get('tty');
    run {sudo => 1, tty => !! $tty}, @cmd;
}

sub _sudo_password {
    my $password;
    print "Enter sudo password: ";
    ReadMode "noecho";
    chomp($password = ReadLine 0);
    Cinnamon::Config::set('password' => $password);
    ReadMode 0;
    print "\n";
    return $password;
}

sub _host    { 'localhost' }
sub _execute { Cinnamon::Local->new->execute(@_) }

!!1;
