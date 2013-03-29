use strict;
use warnings;
use Test::More;
use Path::Class;

use base qw(Test::Class);

use Cinnamon::CommandBuilder;

sub _build : Tests {
    subtest default => sub {
        my @command = qw{ls -la --color=never};
        my $c = Cinnamon::CommandBuilder->new;
        is_deeply [ $c->build(@command) ],
            [ 'ls', '-la', '--color=never' ];
        is_deeply [ $c->build( join ' ', @command ) ],
            [ '/bin/bash', '-l', '-c', 'ls -la --color=never' ];
    };

    subtest 'shell_exec' => sub {
        my @command = qw{ls -la --color=never};
        subtest 'no_shell' => sub {
            my $c = Cinnamon::CommandBuilder->new( shell => [] );
            is_deeply [ $c->build(@command) ],
                [ 'ls',  '-la', '--color=never' ];
            is_deeply [ $c->build(join ' ', @command) ],
                [ 'ls -la --color=never' ];
        };

        subtest 'change_shell' => sub {
            my $c = Cinnamon::CommandBuilder->new( shell => [qw{/bin/sh -c}] );
            is_deeply [ $c->build(@command) ],
                [ 'ls',  '-la', '--color=never' ];
            is_deeply [ $c->build(join ' ', @command) ],
                [ '/bin/sh', '-c', 'ls -la --color=never' ];
         }
    };

    subtest sudo => sub {
        my @command = qw{ls -la --color=never /root};
        my $c = Cinnamon::CommandBuilder->new( sudo => 1 );
        is_deeply [ $c->build(@command) ],
            [ 'sudo', '-Sk', '--',  'ls', '-la', '--color=never', '/root' ];
        is_deeply [ $c->build(join ' ', @command) ],
            [ 'sudo', '-Sk', '--', '/bin/bash', '-l', '-c', 'ls -la --color=never /root' ];
    };

    subtest 'no_sudo_opts' => sub {
        my @command = qw{ls -la --color=never /root};
        my $c = Cinnamon::CommandBuilder->new( sudo => 1, sudo_opts => [] );
        is_deeply [ $c->build(@command) ],
            [ 'sudo', '--',  'ls', '-la', '--color=never', '/root' ];
        is_deeply [ $c->build(join ' ', @command) ],
            [ 'sudo', '--', '/bin/bash', '-l', '-c', 'ls -la --color=never /root' ];
    };

    subtest 'user/group' => sub {
        my @command = qw{ls -la --color=never /root};
        my $c = Cinnamon::CommandBuilder->new( sudo => 1, sudo_user => 'app', sudo_group => 'www' );
        is_deeply [ $c->build(@command) ],
            [ 'sudo', '-Sk', '-u', 'app', '-g', 'www', '--',  'ls', '-la', '--color=never', '/root' ];
        is_deeply [ $c->build(join ' ', @command) ],
            [ 'sudo', '-Sk', '-u', 'app', '-g', 'www', '--', '/bin/bash', '-l', '-c', 'ls -la --color=never /root' ];
    };

    subtest 'has_control_operator' => sub {
        my @command = qw{ls -la --color=never && whoami};
        my $c = Cinnamon::CommandBuilder->new;
        is_deeply [ $c->build(@command) ],
            [ 'ls', '-la', '--color=never', '&&', 'whoami' ],
            "'&&' is not interpreted as control operator";
        is_deeply [ $c->build( join ' ', @command ) ],
            [ '/bin/bash', '-l', '-c', 'ls -la --color=never && whoami' ];
    };
}

__PACKAGE__->runtests;

