package Cinnamon::Runner;
use strict;
use warnings;

use Cinnamon::Config;

sub start {
    my ($class, $host, @args) = @_;
    my $task = Cinnamon::Config::get_task;
       $task->($host, @args);
}

!!1;
