use strict;
use warnings;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use parent qw(Test::Class);
use Test::More;

sub compile : Tests {
    use_ok "Cinnamon::Task";
}

__PACKAGE__->runtests;
