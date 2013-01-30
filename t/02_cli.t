use strict;
use warnings;
use Test::More;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use base qw(Test::Class);

use Test::Cinnamon::CLI;

sub _help : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->run('--help');
    is $app->system_error, "Usage: cinnamon [--config=<path>] [--help] [--info] <role> <task>\n";
}

sub _info : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy.pl", <<CONFIG);
use Cinnamon::DSL;
role production  => sub { 'example.com'  }, { foo => 'bar' };
task update      => sub { 'do something' };
CONFIG
    $app->run('--info');
    is $app->system_output, <<"OUTPUT";
\e[37m---
roles:
  production:
    hosts: example.com
    params:
      foo: bar
tasks:
  update: !!perl/code '{ "DUMMY" }'
\e[0m
OUTPUT
}

sub _no_config : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->run('role', 'task');
    is $app->system_error, "cannot find config file for deploy : config/deploy.pl\nUsage: cinnamon [--config=<path>] [--help] [--info] <role> <task>\n";
}

sub _valid : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy.pl", <<CONFIG);
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task echo_user => sub {
    print(get 'user');
};
CONFIG
    $app->run('test', 'echo_user');
    like $app->system_output, qr{app};
}

sub _change_config_name : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy_changed.pl", <<CONFIG);
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task echo_user => sub {
    print(get 'user');
};
CONFIG
    $app->run('--config=config/deploy_changed.pl', 'test', 'echo_user');
    like $app->system_output, qr{app};
}

sub _read_command_line_args : Tests {
    my $app = Test::Cinnamon::CLI::cli();
    $app->dir->touch("config/deploy.pl", <<'CONFIG');
use Cinnamon::DSL;
role test => 'localhost';
task args => sub {
    my $host  = shift;
    printf "%s\t%s\n", get('args1'), get('args2');
};
CONFIG
    $app->run('test', 'args', '-s', 'args1=foo', '-s', 'args2=bar');
    like $app->system_output, qr{foo\tbar};
}

__PACKAGE__->runtests;
