package Cinnamon::HandleManager;
use strict;
use warnings;

use Cinnamon::Logger;

use AnyEvent;
use AnyEvent::Handle;

use POSIX;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub register_fh {
    my ($self, $name, $fh) = @_;
    my $handle_container = $self->{handle_container} ||= {};
    $handle_container->{$name} = {
        fh => $fh,
        output_lines => [],
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
                $handle->push_read(line => qr|\r?\n|, sub {
                    my $line = $_[1];
                    push @{$info->{output_lines}}, $line;
                    log info => sprintf "[%s :: %s] %s",
                        $self->{host}, $name, $line;
                });
            },
            on_eof => sub {
                $cv->end;
            },
            on_error => sub {
                my $msg = $_[2];
                log error => sprintf "[%s :: %s] %s", $self->{host}, $name, $msg
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

1;
