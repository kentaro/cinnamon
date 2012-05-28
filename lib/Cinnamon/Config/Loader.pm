package Cinnamon::Config::Loader;
use strict;
use warnings;

use Cinnamon::Logger;

sub load {
    my ($class, %args) = @_;
    my $config = $args{config};

    do $config;

    if ($@) {
        log error => $@;
        exit 1;
    }

    if ($!) {
        log error => $!;
        exit 1;
    }
}

!!1;
