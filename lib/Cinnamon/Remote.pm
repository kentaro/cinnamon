package Cinnamon::Remote;
use strict;
use warnings;
use Net::OpenSSH;

use Cinnamon::HandleManager;
use Cinnamon::Logger;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub connection {
    my $self = shift;
    return Net::OpenSSH->new(
        $self->{host}, user => $self->{user},
    );
}

sub host { $_[0]->{host} }

sub execute {
    my ($self, $opt, @cmd) = @_;
    my $host = $self->host || '';
    my $conn = $self->connection;
    my $exec_opt = {};

    if (defined $opt && $opt->{sudo}) {
        @cmd = ('sudo', '-Sk', @cmd);
    }

    my ($stdin, $stdout, $stderr, $pid) = $conn->open3({
        tty => $opt->{tty},
    }, join ' ', @cmd);

    if ($opt->{password}) {
        print $stdin "$opt->{password}\n";
    }

    my $hm = Cinnamon::HandleManager->new(host => $self->{host});
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

sub DESTROY {
    my $self = shift;
       $self->{connection} = undef;
}

!!1;
