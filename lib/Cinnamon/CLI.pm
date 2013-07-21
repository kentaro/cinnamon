package Cinnamon::CLI;
use strict;
use warnings;

use Getopt::Long;
use Cinnamon::Context;

use constant { SUCCESS => 0, ERROR => 1 };

sub new {
    my $class = shift;
    bless { }, $class;
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

    # --help option
    if ($self->{help}) {
        $self->usage;
        return SUCCESS;
    }

    # check config exists
    $self->{config} ||= 'config/deploy.pl';
    if (!-e $self->{config}) {
        $self->print("cannot find config file for deploy : $self->{config}\n");
        $self->usage;
        return ERROR;
    }

    # check role and task exists
    my $role = shift @ARGV;
    my @tasks = @ARGV;
    if (!$self->{info} && (!$role || scalar @tasks == 0)) {
        $self->print("please specify role and task\n");
        $self->usage;
        return ERROR;
    }

    @tasks = (undef) if (@tasks == 0);
    my $error_occured = 0;
    my $context = Cinnamon::Context->new;
    local $Cinnamon::Context::CTX = $context;
    for my $task (@tasks) {
        my ($success, $error) = $context->run(
            $role,
            $task,
            config            => $self->{config},
            override_settings => $self->{override_settings},
            info              => $self->{info},
        );
        last if ($self->{info});

        # check execution error
        $error_occured ||= ! defined $success;
        $error_occured ||= scalar @$error > 0;

        last if ($error_occured && !$self->{ignore_errors});
        print "\n";
    }

    return $error_occured ? ERROR : SUCCESS;
}

sub usage {
    my $self = shift;
    my $msg = <<"HELP";
Usage: cinnamon [--config=<path>] [--set=<parameter>] [--ignore-errors] [--help] [--info] <role> <task ...>
HELP
    $self->print($msg);
}

sub print {
    my ($self, $msg) = @_;
    print STDERR $msg;
}

!!1;
