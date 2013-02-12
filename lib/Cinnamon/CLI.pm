package Cinnamon::CLI;
use strict;
use warnings;

use Getopt::Long;
use Cinnamon;

sub new {
    my $class = shift;
    bless { }, $class;
}

sub cinnamon {
    my $self = shift;
    $self->{cinnamon} ||= Cinnamon->new;
}

sub run {
    my ($self, @args) = @_;

    local @ARGV = @args;
    my $p = Getopt::Long::Parser->new(
        config => ["no_ignore_case", "pass_through"],
    );
    $p->getoptions(
        "h|help"     => \$self->{help},
        "i|info"     => \$self->{info},
        "c|config=s" => \$self->{config},
        "s|set=s%"   => \$self->{override_settings},
        "I|ignore-errors" => \$self->{ignore_errors},
    );
    return $self->usage if $self->{help};

    $self->{config} ||= 'config/deploy.pl';
    if (!-e $self->{config}) {
        $self->print("cannot find config file for deploy : $self->{config}\n");
        return $self->usage;
    }

    my $role = shift @ARGV;
    my @tasks = @ARGV;
    if (!$self->{info} && (!$role && @tasks == 0)) {
        $self->print("please specify role and task\n");
        return $self->usage;
    }

    @tasks = (undef) if (@tasks == 0);
    for my $task (@tasks) {
        my ($success, $error) = $self->cinnamon->run(
            $role,
            $task,
            config            => $self->{config},
            override_settings => $self->{override_settings},
            info              => $self->{info},
        );
        last if (!defined $success || $self->{info});
        last if ($error && @$error > 0 && !$self->{ignore_errors});
        print "\n";
    }
}

sub usage {
    my $self = shift;
    my $msg = <<"HELP";
Usage: cinnamon [--config=<path>] [--help] [--info] <role> <task ...>
HELP
    $self->print($msg);
}

sub print {
    my ($self, $msg) = @_;
    print STDERR $msg;
}

!!1;
