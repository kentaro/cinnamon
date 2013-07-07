use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use parent qw(Test::Class);
use Test::More;

use Cinnamon::Context;
use Cinnamon::Config ();

sub role : Tests {
    subtest 'role without params' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_role('name1', 'host1');
        $ctx->add_role('name2', 'host2');

        is $ctx->get_role('name1')->name, 'name1';
        is_deeply $ctx->get_role('name1')->get_hosts, ['host1'];
        is_deeply $ctx->get_role_hosts('name1'), ['host1'];

        is $ctx->get_role('name2')->name, 'name2';
        is_deeply $ctx->get_role('name2')->get_hosts, ['host2'];
        is_deeply $ctx->get_role_hosts('name2'), ['host2'];
    };

    subtest 'role with params' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_role('name1', 'host1', { hoge => 'fuga' });

        is_deeply $ctx->get_role_hosts('name1'), ['host1'];
        is Cinnamon::Config::get('hoge'), 'fuga';

        Cinnamon::Config::reset();
    };
}

sub task : Tests {
    subtest 'simple task definition' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_task('task1' => sub { });
        $ctx->add_task('task2' => sub { });

        is $ctx->get_task('task1')->name, 'task1';
        is $ctx->get_task('task2')->name, 'task2';
    };

    subtest 'nest task definition' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_task('task1' => {
            nest1 => sub { },
            nest2 => {
                subnest1 => sub { },
            },
        });
        $ctx->add_task('task2' => sub {});

        is $ctx->get_task('task1:nest1')->name, 'task1:nest1';
        is $ctx->get_task('task1:nest2:subnest1')->name, 'task1:nest2:subnest1';
        is $ctx->get_task('task2')->name, 'task2';
    };
}

__PACKAGE__->runtests;
