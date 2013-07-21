package Cinnamon::Logger;
use strict;
use warnings;
use parent qw(Exporter);

use Term::ANSIColor ();

our @EXPORT = qw(
    log
);

my %COLOR = (
    success => 'green',
    error   => 'red',
    info    => 'white',
);

sub log ($$) {
    my ($type, $message) = @_;
    my $color ||= $COLOR{$type};

    $message = Term::ANSIColor::colored $message, $color if $color;
    $message .= "\n";

    my $fh = $type eq 'error' ? *STDERR : *STDOUT;

    print $fh $message;

    return;
}

!!1;
