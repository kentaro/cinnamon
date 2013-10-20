use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use parent qw(Test::Class);
use Test::More;
use Test::Fatal;
use Test::Mock::Guard qw(mock_guard);

use Cinnamon::Context;

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
        is $ctx->get_param('hoge'), 'fuga';
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

sub param : Tests {
    subtest 'simple param' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->set_param('key1' => 'value1');
        $ctx->set_param('key2' => 'value2');

        is $ctx->get_param('key1'), 'value1';
        is $ctx->get_param('key2'), 'value2';
    };

    subtest 'code param' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->set_param('key1' => sub { 'value1' });
        $ctx->set_param('key2' => sub {
            my ($count) = @_;
            return "value$count";
        });

        is $ctx->get_param('key1'), 'value1';
        is $ctx->get_param('key2', 2), 'value2';
        is $ctx->get_param('key2', 3), 'value3';
    };
}

sub call_task : Tests {
    subtest 'undefined task' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_task('task1' => sub { });
        my $E = exception { $ctx->call_task('task2', 'host1') };
        like $E, qr{undefined task : 'task2'};
    };

    subtest 'call task' => sub {
        my $ctx = Cinnamon::Context->new;
        $ctx->add_task('task1' => sub { });
        $ctx->add_task('task2' => {
            nest1 => sub { },
        });

        my $last_args;
        my $g = mock_guard "Cinnamon::Task", {
            execute => sub { $last_args = \@_ },
        };

        note "call a simple task";
        $ctx->call_task('task1', 'host1');
        is $last_args->[0]->name, 'task1';
        is $last_args->[1], 'host1';

        note "call a nested task";
        $ctx->call_task('task2:nest1', 'host2');
        is $last_args->[0]->name, 'task2:nest1';
        is $last_args->[1], 'host2';
    };
}

__PACKAGE__->runtests;
