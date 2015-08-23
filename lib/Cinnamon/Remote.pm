package Cinnamon::Remote;
use strict;
use warnings;

use Moo;

use Net::OpenSSH;

use Cinnamon::HandleManager;
use Cinnamon::Logger;

has [qw(host user)] => (is => 'ro');

sub connection {
    my $self = shift;
    return Net::OpenSSH->new(
        $self->host, user => $self->user,
    );
}

sub execute {
    my ($self, $commands, $opts) = @_;
    my $host = $self->host || '';
    my $conn = $self->connection;

    if ($opts->{sudo}) {
        @$commands = ('sudo', '-Sk', @$commands);
    }

    my ($stdin, $stdout, $stderr, $pid) = $conn->open3({
        tty => $opts->{tty},
    }, join ' ', @$commands) or die "open3 failed: " . $conn->error;

    if ($opts->{password}) {
        print $stdin "$opts->{password}\n";
    }

    my $hm = Cinnamon::HandleManager->new(host => $self->host);
    $hm->register_fh(stdout => $stdout);
    $hm->register_fh(stderr => $stderr);
    $hm->start_async_read();

    my $stdout_str = $hm->captured_str('stdout');
    my $stderr_str = $hm->captured_str('stderr');

    local $? = 0;
    waitpid($pid, 0);
    my $exitcode = $?;

    +{
        stdout    => $stdout_str,
        stderr    => $stderr_str,
        has_error => $exitcode > 0,
        error     => $exitcode,
    };
}

!!1;
