use strict;
use warnings;
use Test::More;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use base qw(Test::Class);

use Test::Cinnamon::CLI;
use Cinnamon qw(CTX);
use Cinnamon::DSL ();
use Cinnamon::Context;

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
    no strict 'refs';
    no warnings 'redefine';
    local *Cinnamon::Local::execute = sub {
        my ($self, $commands) = @_;
        is_deeply $commands, [qw/command foo/];
        +{}
    };
    local *Cinnamon::Remote::execute = sub {
        my ($self, $commands, $opts) = @_;
        is_deeply $commands, [qw/command bar/];
        +{}
    };
    $app->run('test', 'test_remote');
}

__PACKAGE__->runtests;
