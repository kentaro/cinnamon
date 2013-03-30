use strict;
use warnings;
use Test::More;
use Test::SharedFork;
use Test::Flatten;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use base qw(Test::Class);

use Test::Cinnamon::CLI;
use Cinnamon::DSL ();
use Cinnamon::CommandBuilder;

{
    package TESTIN;
    sub TIEHANDLE {
        my $class = shift;
        my @in_lines = map { "$_\n" } @_;
        bless \@in_lines, $class;
    }
    sub READLINE { shift @{ $_[0] } }
}

sub setup : Test(setup) {
    Cinnamon::Config::reset;
}

sub sudo : Tests {
    subtest _sudo_password => sub {
        Cinnamon::Config::reset;
        my $pass = "mypassword";
        tie local *STDIN, 'TESTIN', $pass;
        is Cinnamon::DSL::_sudo_password(), $pass;
        is Cinnamon::Config::get('password'), $pass;
    };

    subtest _print_execute_command_before_enter_sudo_password => sub {
        Cinnamon::Config::reset;
        my $app = Test::Cinnamon::CLI::cli();
        $app->dir->touch("config/deploy.pl", <<'CONFIG');
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task sudo_cmd => sub {
    sudo "command";
};
CONFIG
        no strict 'refs';
        no warnings 'redefine';
        my $out;
        my $orig_log = *{'Cinnamon::Logger::log'}{CODE};
        local *{'Cinnamon::DSL::log'} = sub ($$) {
            $out .= $_[1] . "\n"; # TYPE, MESSAGE
            $orig_log->(@_);
        };
        local *Cinnamon::DSL::_sudo_password = sub {
            my $cmd_str = Cinnamon::CommandBuilder->new(sudo => 1)->build('command');
            like $out, qr/\[localhost :: executing\] $cmd_str/;
        };
        local *Cinnamon::Local::_execute = sub {};
        $app->run('test', 'sudo_cmd');
    };
}

sub remote : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy.pl", <<'CONFIG');
use Cinnamon::DSL;
set user => 'app';
set password => 'password';
role test => 'localhost';
task test_remote => sub {
    my ($host, @args) = @_;

    run 'command', 'foo';
    sudo 'command', 'foo';

    remote {
        run 'command', 'bar';
        sudo 'command', 'bar';
    } $host;

    run 'command', 'foo';
    sudo 'command', 'foo';
};
CONFIG

    no warnings 'redefine';
    local *Cinnamon::Local::_execute = sub {
        my ($self, $opt, @cmd) = @_;
        my $c = Cinnamon::CommandBuilder->new($opt);
        is_deeply \@cmd, [ $c->build(@cmd) ];
    };
    local *Cinnamon::Remote::_execute = sub {
        my ($self, $opt, @cmd) = @_;
        my $c = Cinnamon::CommandBuilder->new($opt);
        is_deeply \@cmd, [ $c->build(@cmd) ];
    };
    $app->run('test', 'test_remote');
}

__PACKAGE__->runtests;
