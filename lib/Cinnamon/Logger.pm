package Cinnamon::Logger;
use strict;
use warnings;
use parent qw(Exporter);

use Term::ANSIColor ();
use Log::Dispatch;
use Log::Dispatch::Screen;

use Cinnamon::Config;

our @EXPORT = qw(
    log
);

my $logger;
sub logger () {
    $logger ||= do {
        my $level = Cinnamon::Config::get('log_level') || 'info';
        my $logger = Log::Dispatch->new;
           $logger->add(
               Log::Dispatch::Screen->new(
                   name      => 'screen',
                   min_level => $level,
               )
           );
           $logger;
    };
}

my %COLOR = (
    error => 'red',
);

sub log ($$) {
    my ($level, $message) = @_;
    my $color = $COLOR{$level} || 'green';

    $message = Term::ANSIColor::colored $message, $color;
    $message .= "\n";

    logger->log(level => $level, message => $message);
}

!!1;
