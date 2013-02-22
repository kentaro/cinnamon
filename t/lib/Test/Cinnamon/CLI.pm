package Test::Cinnamon::CLI;
use strict;
use warnings;

our @EXPORT = qw(cli);

use Test::Requires qw(Directory::Scratch);

use Cinnamon::CLI;

sub cli {
    my $dir = Directory::Scratch->new();
    chdir $dir;
    $dir->mkdir('config');

    my $app = Test::Cinnamon::CLI::App->new(dir => $dir);
    return $app;
}

package Test::Cinnamon::CLI::App;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cinnamon::CLI;

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
    my $success;
    ($self->{system_output}, $self->{system_error}) = capture {
        $success = Cinnamon::CLI->new->run(@args);
    };
    return $success;
}

sub system_output {
    return $_[0]->{system_output};
}

sub system_error {
    return $_[0]->{system_error};
}

1;

