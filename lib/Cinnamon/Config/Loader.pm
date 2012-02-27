package Cinnamon::Config::Loader;
use strict;
use warnings;

use Cinnamon::Logger;

sub load {
    my ($class, @args) = @_;
    my $config = 'config/deploy.pl';

    if (@args && -e $args[-1]) {
        $config = pop @args;
    }

    if (!-e $config) {
        log error => 'usage: cinnamon $role $task [@args $config]';
        exit 1;
    }

    do $config;

    if ($@) {
        log error => $@;
        exit 1;
    }

    if ($!) {
        log error => $!;
        exit 1;
    }

    @args;
}

!!1;
