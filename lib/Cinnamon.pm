package Cinnamon;
use strict;
use warnings;
use 5.008008;

our $VERSION = '0.01';

use Cinnamon::Config;
use Cinnamon::Runner;

sub run {
    my ($class, $role, $task, @args) = @_;

    Cinnamon::Config::set role => $role;
    Cinnamon::Config::set task => $task;

    for my $host (@{Cinnamon::Config::get_role || []}) {
        Cinnamon::Runner->start($host, @args);
    }
}

1;
__END__

=encoding utf8

=head1 NAME

Cinnamon - blah blah blah

=head1 SYNOPSIS

  use Cinnamon;

=head1 DESCRIPTION

Cinnamon is

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
