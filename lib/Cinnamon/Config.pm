package Cinnamon::Config;
use strict;
use warnings;

use Cinnamon::Config::Loader;
use Cinnamon::Logger;

my %CONFIG;

sub reset () {
    %CONFIG = ();
}

sub set ($$) {
    my ($key, $value) = @_;

    $CONFIG{$key} = $value;
}

sub get ($@) {
    my ($key, @args) = @_;

    my $value = $CONFIG{$key};

    $value = $value->(@args) if ref $value eq 'CODE';
    $value;
}

sub user () {
    get 'user' || do {
        my $user = qx{whoami};
        chomp $user;
        $user;
    };
}

sub load (@) {
    my ($role, $task, %opt) = @_;

    set role => $role;
    set task => $task;

    Cinnamon::Config::Loader->load(config => $opt{config});

    for my $key (keys %{ $opt{override_settings} }) {
        set $key => $opt{override_settings}->{$key};
    }
}

!!1;
