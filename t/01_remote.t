use strict;
use warnings;
use Test::More;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use constant { EXIT_SUCCESS => 0, EXIT_ERROR => 1 };

use Net::OpenSSH;
use Cinnamon::Remote;
use Cinnamon::CommandBuilder;

no strict 'refs';
no warnings 'redefine';

local *Net::OpenSSH::new = sub {
    my ($class, $host, %args) = @_;
    bless {}, $class;
};

sub mock_openssh_system {
    my $opts = {
        error               => 0,
        check_stdin_handler => sub { },
        check_opt_handler   => sub { },
        @_,
    };
    return sub {
        my ( $self, $opt, @cmd ) = @_;
        my $stdin = $opt->{stdin_data};
        $opts->{check_stdin_handler}->($stdin);
        $opts->{check_opt_handler}->($opt);
        my $cmd_str = _cmd_str(@cmd) . "\n";
        print $cmd_str;
        print STDERR $cmd_str;
        return !$opts->{error};
    };
}

sub _cmd_str {
    my @cmd = @_;
    join ' ', map { "'$_'" } @cmd;
}

subtest 'run success' => sub {
    local *Net::OpenSSH::system = mock_openssh_system();
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    my @cmd = qw{ ls / };
    my $res = $remote->execute(undef, @cmd);
    my $cb = Cinnamon::CommandBuilder->new();
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok !$res->{has_error};
    is $res->{error}, EXIT_SUCCESS;
};

subtest 'run failure' => sub {
    local *Net::OpenSSH::system = mock_openssh_system(error => 1);
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    my @cmd = qw{ ls / };
    my $res = $remote->execute(undef, @cmd);
    my $cb = Cinnamon::CommandBuilder->new();
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok $res->{has_error};
    is $res->{error}, EXIT_ERROR;
};

subtest 'sudo run success' => sub {
    my $password = 'password';
    local *Net::OpenSSH::system = mock_openssh_system(
        check_stdin_handler => sub {
            is $_[0], "$password\n";
        },
    );
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    my @cmd = qw{ ls / };
    my $res = $remote->execute({sudo => 1, password => $password}, @cmd);
    my $cb = Cinnamon::CommandBuilder->new(sudo => 1);
    push @{ $cb->{sudo_opts} }, '-p', '';
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok !$res->{has_error};
    is $res->{error}, EXIT_SUCCESS;
};

subtest 'sudo run with tty' => sub {
    my $password = 'password';
    local *Net::OpenSSH::system = mock_openssh_system(
        check_stdin_handler => sub {
            is $_[0], "$password\n";
        },
        check_opt_handler => sub {
            ok shift->{tty};
        }
    );
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    my @cmd = qw{ ls / };
    my $res = $remote->execute({sudo => 1, password => $password, tty => 1}, @cmd);
    my $cb = Cinnamon::CommandBuilder->new(sudo => 1);
    push @{ $cb->{sudo_opts} }, '-p', '';
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok !$res->{has_error};
    is $res->{error}, EXIT_SUCCESS;
};

done_testing();
