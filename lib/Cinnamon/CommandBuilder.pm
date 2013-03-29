package Cinnamon::CommandBuilder;
use strict;
use warnings;

use String::ShellQuote;

use constant {
    SHELL_DEFAULT       => [qw{ /bin/bash -l -c }],
    SUDO                => 'sudo',
    SUDO_OPT_USER       => '-u',
    SUDO_OPT_GROUP      => '-g',
    SUDO_DEFAULT_OPTS   => ['-Sk'],
    SUDO_ARGS_INDICATOR => '--',
};

sub new {
    my $class = shift;
    my $args = {
        shell      => [ @{ SHELL_DEFAULT() } ],
        sudo       => 0,
        sudo_opts  => [ @{ SUDO_DEFAULT_OPTS() } ],
        sudo_user  => undef,
        sudo_group => undef,
        @_,
    };
    bless $args, $class;
};

sub build {
    my ($self, @cmd) = @_;

    if (@cmd == 1) {
        @cmd = (@{ $self->{shell} }, $cmd[0]);
    }
    if ( $self->{sudo} ) {
        my @sudo_opts = @{ $self->{sudo_opts} || [] };
        push( @sudo_opts, SUDO_OPT_USER, $self->{sudo_user} )
            if ( $self->{sudo_user} );
        push( @sudo_opts, SUDO_OPT_GROUP, $self->{sudo_group} )
            if ( $self->{sudo_group} );
        unshift @cmd, SUDO, @sudo_opts, SUDO_ARGS_INDICATOR;
    }

    wantarray ? @cmd : shell_quote(@cmd);
}

!!1;
