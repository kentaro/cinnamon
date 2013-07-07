package Cinnamon::Config;
use strict;
use warnings;

use Cinnamon;
use Cinnamon::Config::Loader;
use Cinnamon::Logger;

sub user () {
    CTX->get_param('user');
}

sub load (@) {
    my ($role, $task, %opt) = @_;

    CTX->set_param(role => $role);
    CTX->set_param(task => $task);

    Cinnamon::Config::Loader->load(config => $opt{config});

    for my $key (keys %{ $opt{override_settings} }) {
        CTX->set_param($key => $opt{override_settings}->{$key});
    }
}

!!1;
