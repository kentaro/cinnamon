package Cinnamon::Role;
use strict;
use warnings;

use Moo;
use Hash::MultiValue;

has name => (is => 'ro', required => 1);
has hosts => (is => 'ro', required => 1);
has params => (is => 'ro', default => sub { Hash::MultiValue->new });

sub get_hosts {
    my ($self) = @_;
    my $hosts = $self->hosts;
    if (ref $hosts eq 'CODE') {
        return $hosts->();
    }
    return ref $hosts eq 'ARRAY' ? $hosts : [$hosts];
}

sub info {
    my ($self) = @_;
    return +{
        hosts  => $self->get_hosts,
        params => $self->params->as_hashref,
    };
}

1;
