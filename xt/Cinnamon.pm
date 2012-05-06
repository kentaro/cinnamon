package xt::Cinnamon;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(cinnamon);

use Test::Requires qw(Directory::Scratch);

sub cinnamon {
    my $dir = Directory::Scratch->new();
    chdir $dir;
    $dir->mkdir('config');

    my $app = Cinnamon::Tested->new(dir => $dir);
    return $app;
}

1;

package Cinnamon::Tested;
use strict;
use warnings;

use Capture::Tiny qw(capture);

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    $self->{dir} = $args{dir};
    return $self;
}

sub dir {
    return $_[0]->{dir};
}

sub run {
    my ($self, @args) = @_;
    ($self->{system_output}, $self->{system_error}) = capture {
        eval { system(@args) };
        warn $@;
    };
}

sub system_output {
    return $_[0]->{system_output};
}

sub system_error {
    return $_[0]->{system_error};
}

1;
