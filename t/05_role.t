use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use parent qw(Test::Class);
use Test::More;

use Cinnamon::Role;

sub get_hosts : Tests {
    subtest 'single host' => sub {
        my $role = Cinnamon::Role->new(
            name  => 'single',
            hosts => 'localhost',
        );
        is_deeply $role->get_hosts, ['localhost'];
    };

    subtest 'multi hosts' => sub {
        my $role = Cinnamon::Role->new(
            name  => 'multi',
            hosts => ['host1', 'host2'],
        );
        is_deeply $role->get_hosts, ['host1', 'host2'];
    };

    subtest 'code host' => sub {
        my $role = Cinnamon::Role->new(
            name  => 'multi',
            hosts => sub { ['host1', 'host2'] },
        );
        is_deeply $role->get_hosts, ['host1', 'host2'];
    };
}

__PACKAGE__->runtests;
