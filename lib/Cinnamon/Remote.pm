package Cinnamon::Remote;
use strict;
use warnings;
use Net::OpenSSH;

use AnyEvent;
use AnyEvent::Handle;
use POSIX;

use Cinnamon::Logger;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub connection {
    my $self = shift;
       $self->{connection} ||= Net::OpenSSH->new(
           $self->{host}, user => $self->{user}
       );
}

sub host { $_[0]->{host} }

sub execute {
    my ($self, @cmd) = @_;
    my $opt = shift @cmd;
    my $host = $self->host || '';
    my $conn = $self->connection;
    my $exec_opt = {};

    if (defined $opt && $opt->{sudo}) {
        @cmd = ('sudo', '-Sk', @cmd);
    }

    my ($stdin, $stdout, $stderr, $pid) = $conn->open_ex({
        stdin_pipe => 1,
        stdout_pipe => 1,
        stderr_pipe => 1,
        tty => $opt->{tty},
    }, join ' ', @cmd);

    if ($opt->{password}) {
        print $stdin "$opt->{password}\n";
    }

    my $cv = AnyEvent->condvar;
    my $exitcode;
    my ($fhout, $fherr);

    my $stdout_str = '';
    my $stderr_str = '';

    my $end = sub {
        undef $fhout;
        undef $fherr;
        waitpid $pid, 0;
        $exitcode = $?;
        $cv->send;
    };

    my $print = sub {
        my ($s, $handle) = @_;
        my $type = $handle eq 'stdout' ? 'info' : 'error';
        while ($s =~ s{([^\x0D\x0A]*)\x0D?\x0A}{}) {
            log $type => sprintf "[%s :: %s] %s",
                $host, $handle, $1;
        }
        if (length $s) {
            log $type => sprintf "[%s :: %s] %s",
                $host, $handle, $s;
        }
    };

    $fhout = AnyEvent::Handle->new(
        fh => $stdout,
        on_read => sub {
            $stdout_str .= $_[0]->rbuf;
            $print->($_[0]->rbuf => 'stdout');
            substr($_[0]->{rbuf}, 0) = '';
        },
        on_eof => sub {
            undef $stdout;
            $end->() if not $stdout and not $stderr;
        },
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            log error => sprintf "[%s] STDOUT: %s (%d)", $host, $message, $!
                unless $! == POSIX::EPIPE;
            undef $stdout;
            $end->() if not $stdout and not $stderr;
        },
    );

    $fherr = AnyEvent::Handle->new(
        fh => $stderr,
        on_read => sub {
            $stderr_str .= $_[0]->rbuf;
            $print->($_[0]->rbuf => 'stderr');
            substr($_[0]->{rbuf}, 0) = '';
        },
        on_eof => sub {
            undef $stderr;
            $end->() if not $stdout and not $stderr;
        },
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            log error => sprintf "[%s] STDERR: %s (%d)", $host, $message, $!
                unless $! == POSIX::EPIPE;
            undef $stderr;
            $end->() if not $stdout and not $stderr;
        },
    );

    $cv->recv;

    if ($exitcode != 0) {
        log error => sprintf "[%s] Status: %d", $host, $exitcode;
    }

    +{
        stdout    => $stdout_str,
        stderr    => $stderr_str,
        has_error => !!$self->connection->error,
        error     => $self->connection->error,
    };
}

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
