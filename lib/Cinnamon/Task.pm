package Cinnamon::Task;
use strict;
use warnings;

use Moo;
use Hash::MultiValue;

has name => (is => 'ro', required => 1);
has code => (is => 'ro', required => 1);

sub info {
    my ($self) = @_;
    return +{
        $self->name => $self->code,
    };
}

1;
