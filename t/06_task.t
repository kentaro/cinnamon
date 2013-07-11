use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use parent qw(Test::Class);
use Test::More;

use Cinnamon::Task;

sub info : Tests {
    my $task = Cinnamon::Task->new(
        name => 'name',
        code => sub { },
    );
    my $info = $task->info;
    ok $info->{name};
}

__PACKAGE__->runtests;
