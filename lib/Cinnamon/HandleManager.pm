package Cinnamon::HandleManager;
use strict;
use warnings;

use Cinnamon::Logger;

use AnyEvent;
use AnyEvent::Handle;

use POSIX;

# HOST(%1$s), NAME(%2$s), MESSAGE(%3$s)
use constant OUTPUT_FORMAT => "[%s :: %s] %s";

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub register_fh {
    my ($self, $name, $fh, $format) = @_;
    my $handle_container = $self->{handle_container} ||= {};
    $handle_container->{$name} = {
        fh => $fh,
        output_lines => [],
        format => $format || OUTPUT_FORMAT,
    };
}

sub start_async_read {
    my ($self) = @_;
    my $handle_container = $self->{handle_container} or return;

    my $cv = AnyEvent->condvar;
    my $handles = [];
    for my $name (keys %$handle_container) {
        my $info = $handle_container->{$name};

        $cv->begin;
        my $handle; $handle = AnyEvent::Handle->new(
            fh => $info->{fh},
            on_read => sub {
                $handle->push_read(line => sub {
                    my $line = $_[1];
                    push @{$info->{output_lines}}, $line;
                    log info => sprintf $info->{format},
                        $self->{host}, $name, $line;
                });
            },
            on_eof => sub {
                $cv->end;
            },
            on_error => sub {
                if (my $buf_remain = $handle->rbuf) {
                    push @{$info->{output_lines}}, $buf_remain;
                    log info => sprintf $info->{format},
                        $self->{host}, $name, $buf_remain;
                }
                my $msg = $_[2];
                log error => sprintf $info->{format}, $self->{host}, $name, $msg
                    unless $! == POSIX::EPIPE;
                $cv->end;
            },
        );
        push @$handles, $handle;
    }

    $cv->recv;

    for my $h (@$handles) {
        $h->destroy;
    }
}

sub captured_str {
    my ($self, $name) = @_;
    my $hinfo = $self->{handle_container}->{$name} or return '';
    my $str = join("\n", @{$hinfo->{output_lines}});
    return $str;
}

sub handle {
    my ( $self, $code, $format ) = @_;
    my ( $rout, $wout ) = mkpipe();
    my ( $rerr, $werr ) = mkpipe();

    my $pid = fork;
    Carp::croak "Can't fork: $!" unless ( defined $pid );

    unless ($pid) { # child
        close $rout;
        close $rerr;

        my $old = select;
        close STDOUT; open STDOUT, '>&', $wout; select STDOUT; $| = 1;
        close STDERR; open STDERR, '>&', $werr; select STDERR; $| = 1;
        select $old;

        close $wout;
        close $werr;

        eval { $code->() };

        ($@) ? exit(1) : exit(0);
    }

    close $wout;
    close $werr;

    $self->register_fh(stdout => $rout, $format);
    $self->register_fh(stderr => $rerr, $format);
    $self->start_async_read();

    local $? = 0;
    waitpid( $pid, 0 );
    my $exitcode = $? >> 8;

    my $stdout = $self->captured_str('stdout');
    my $stderr = $self->captured_str('stderr');

    return ($stdout, $stderr, $exitcode);
}

use Symbol;
sub mkpipe {
    my ( $r, $w );
    $r = Symbol::gensym();
    $w = Symbol::gensym();
    pipe $r, $w or Carp::croak "can't open pipe";
    my $old = select;
    select $r; $| = 1;
    select $w; $| = 1;
    select $old;
    return ( $r, $w );
}

1;
