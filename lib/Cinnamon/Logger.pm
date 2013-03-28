package Cinnamon::Logger;
use strict;
use warnings;
use parent qw(Exporter);

use Term::ANSIColor ();

use Cinnamon::Config;

our @EXPORT = qw(
    log
);

our $OUTPUT_COLOR = 1;

my %COLOR = (
    success => 'green',
    error   => 'red',
    info    => 'white',
);

sub log ($$) {
    my ($type, $message) = @_;
    my $color = !!$OUTPUT_COLOR ? $COLOR{$type} : 0;

    $message = Term::ANSIColor::colored $message, $color if $color;
    $message .= "\n";

    my $fh = $type eq 'error' ? *STDERR : *STDOUT;

    print $fh $message;

    return;
}

!!1;
