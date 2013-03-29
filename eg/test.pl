use strict;
use warnings;

use Cinnamon::DSL;

set user     => 'myuser';
set password => 'mypassword';

role test => 'localhost';

# Tasks
task local => {
    simple => sub {
        run 'echo -n STDOUT && echo -n hoge';
        run 'echo STDOUT && echo foo';
        run qw{ echo -n STDOUT };
        run qw{ echo STDOUT };
        run qw{ /bin/sh -c }, 'echo -n STDERR >&2';
        run qw{ /bin/sh -c }, 'echo STDERR >&2';

        run 'for i in $(seq 1 5); do date; sleep 1; done';
        run 'for i in $(seq 1 5); do echo -n $i; sleep 1; done';
        run 'for i in $(seq 1 5); do echo $i 1>&2; sleep 1; done';

    },
    sudo => sub {
        sudo 'echo -n STDOUT';
        sudo 'echo STDOUT';
        sudo qw{ echo -n STDOUT };
        sudo qw{ echo STDOUT };
        sudo qw{ /bin/sh -c }, 'echo -n STDERR >&2';
        sudo qw{ /bin/sh -c }, 'echo STDERR >&2';

        sudo 'for i in $(seq 1 5); do date; sleep 1; done';
        sudo 'for i in $(seq 1 5); do echo -n $i; sleep 1; done';
        sudo 'for i in $(seq 1 5); do echo $i 1>&2; sleep 1; done';
    },
    fail_simple => sub {
        run 'non_existing_command';
    },
    fail_sudo => sub {
        sudo 'non_existing_command';
    },
};

task remote => {
    simple => sub {
        my ($host, @args) = @_;
        remote {
            run 'echo -n STDOUT && echo -n hoge';
            run 'echo STDOUT && echo foo';
            run qw{ echo -n STDOUT };
            run qw{ echo STDOUT };
            run qw{ /bin/sh -c }, 'echo -n STDERR >&2';
            run qw{ /bin/sh -c }, 'echo STDERR >&2';

            run 'for i in $(seq 1 5); do date; sleep 1; done';
            run 'for i in $(seq 1 5); do echo -n $i; sleep 1; done';
            run 'for i in $(seq 1 5); do echo $i 1>&2; sleep 1; done';
        } $host;

    },
    sudo => sub {
        my ($host, @args) = @_;
        remote {
            sudo 'echo -n STDOUT';
            sudo 'echo STDOUT';
            sudo qw{ echo -n STDOUT };
            sudo qw{ echo STDOUT };
            sudo qw{ /bin/sh -c }, 'echo -n STDERR >&2';
            sudo qw{ /bin/sh -c }, 'echo STDERR >&2';

            sudo 'for i in $(seq 1 5); do date; sleep 1; done';
            sudo 'for i in $(seq 1 5); do echo -n $i; sleep 1; done';
            sudo 'for i in $(seq 1 5); do echo $i 1>&2; sleep 1; done';
        } $host;
    },
};
