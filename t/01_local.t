use strict;
use warnings;
use Test::More;
use Path::Class;
use lib file(__FILE__)->dir->file('lib')->stringify;

use constant { EXIT_SUCCESS => 0, EXIT_ERROR => 1 };

use Cinnamon::Local;
use Cinnamon::CommandBuilder;

no strict 'refs';
no warnings 'redefine';

sub mock_ipc_run {
    my $opts = {
        error               => 0,
        check_stdin_handler => sub { },
        @_,
    };
    return sub {
        my ( $cmd, $stdin ) = @_;
        $opts->{check_stdin_handler}->($$stdin);
        my $cmd_str = _cmd_str(@$cmd) . "\n";
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
    local *IPC::Run::run = mock_ipc_run();
    my $local = Cinnamon::Local->new();
    my @cmd = qw{ ls / };
    my $res = $local->execute(undef, @cmd);
    my $cb = Cinnamon::CommandBuilder->new();
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok !$res->{has_error};
    is $res->{error}, EXIT_SUCCESS;
};

subtest 'run failure' => sub {
    local *IPC::Run::run = mock_ipc_run(error => 1);
    my $local = Cinnamon::Local->new();
    my @cmd = qw{ ls / };
    my $res = $local->execute(undef, @cmd);
    my $cb = Cinnamon::CommandBuilder->new();
    my $cmd_str = _cmd_str($cb->build(@cmd));
    is $res->{stdout}, $cmd_str;
    is $res->{stderr}, $cmd_str;
    ok $res->{has_error};
    is $res->{error}, EXIT_ERROR;
};

subtest 'sudo run success' => sub {
    my $password = 'password';
    local *IPC::Run::run = mock_ipc_run(
        check_stdin_handler => sub {
            is $_[0], "$password\n";
        },
    );
    my $remote = Cinnamon::Local->new();
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

done_testing();
