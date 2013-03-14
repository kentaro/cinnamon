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
            like $out, qr/\[localhost :: executing\] command/;
        };
        local *Cinnamon::Local::execute = sub {};
        $app->run('test', 'sudo_cmd');
    };
}

sub remote : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy.pl", <<'CONFIG');
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task test_remote => sub {
    my ($host, @args) = @_;
    remote {
        local $_ = \"test"; # SCALAR_REF
        run "command01";
        sudo "command02";
        local $_ = [qw/foo bar buz/]; # ARRAY_REF
        run "command01";
        sudo "command02";
    } $host;
};
CONFIG
    no strict 'refs';
    no warnings 'redefine';
    local *Cinnamon::DSL::run = sub {
        is ref $_, 'Cinnamon::Remote';
    };
    $app->run('test', 'test_remote');
}

__PACKAGE__->runtests;
