package Cinnamon::Function;
use strict;
use warnings;
use parent qw(
    Exporter
    Cinnamon::Storage
);

use Cinnamon::SSH;
use Cinnamon::Config;

our @EXPORT = qw(
    def
    call
    ssh
    run
    sudo
);

__PACKAGE__->storage({});

# user commands
sub def ($&) {
    my ($name, $code) = @_;
    __PACKAGE__->storage->{$name} = $code;
}

sub call ($@) {
    my ($name, @args) = @_;
    __PACKAGE__->storage->{$name}->(@args);
}

sub ssh (&$) {
    my ($code, $host) = @_;
    local $_ = Cinnamon::SSH->new(
        host => $host,
        user => Cinnamon::Config::user,
    );

    $code->()
}

sub run ($) {
    my ($cmd) = @_;
    $_->execute($cmd);
}

sub sudo ($) {
    my ($cmd) = @_;
    run "sudo $cmd";
}

!!1;
