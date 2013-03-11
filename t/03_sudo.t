use strict;
use warnings;
use Test::More;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use base qw(Test::Class);

use Test::Cinnamon::CLI;
use Cinnamon::DSL ();

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

sub _sudo_passowrd : Tests {
    my $pass = "mypassword";
    tie local *STDIN, 'TESTIN', $pass;
    is Cinnamon::DSL::_sudo_password(), $pass;
    is Cinnamon::Config::get('password'), $pass;
}

sub _print_execute_command_before_enter_sudo_passowrd : Tests {
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
        like $out, qr/\[localhost :: executing\] command/;
    };
    local *Cinnamon::Local::execute = sub {};
    $app->run('test', 'sudo_cmd');
}

__PACKAGE__->runtests;
