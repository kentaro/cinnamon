package Cinnamon::Context;
use strict;
use warnings;

use Moo;

use YAML ();
use Class::Load ();
use Hash::MultiValue;

use Cinnamon::Config qw();
use Cinnamon::Runner;
use Cinnamon::Logger;
use Cinnamon::Role;
use Cinnamon::Task;

our $CTX;

has roles => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has tasks => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

sub run {
    my ($self, $role_name, $task_name, %opts)  = @_;
    Cinnamon::Config::load $role_name, $task_name, %opts;

    if ($opts{info}) {
        $self->dump_info;
        return;
    }

    my $hosts  = $self->get_role_hosts($role_name);
    my $task   = $self->get_task($task_name);
    my $runner = Cinnamon::Config::get('runner_class') || 'Cinnamon::Runner';

    unless (defined $hosts) {
        log 'error', "undefined role : '$role_name'";
        return;
    }
    unless (defined $task) {
        log 'error', "undefined task : '$task_name'";
        return;
    }

    Class::Load::load_class $runner;

    my $result = $runner->start($hosts, $task->code);
    my (@success, @error);

    for my $key (keys %{$result || {}}) {
        if ($result->{$key}->{error}) {
            push @error, $key;
        }
        else {
            push @success, $key;
        }
    }

    log success => sprintf(
        "\n========================\n[success]: %s",
        (join(', ', @success) || ''),
    );

    log error => sprintf(
        "[error]: %s",
        (join(', ', @error)   || ''),
    );

    return (\@success, \@error);
}

sub add_role {
    my ($self, $name, $hosts, $params) = @_;
    $params ||= {};
    my $role = Cinnamon::Role->new(
        name   => $name,
        hosts  => $hosts,
        params => Hash::MultiValue->new(%$params),
    );
    $self->roles->set($name => $role);
}

sub get_role {
    my ($self, $name) = @_;
    return $self->roles->get($name);
}

sub get_role_hosts {
    my ($self, $name) = @_;
    my $role  = $self->get_role($name) or return undef;
    my $hosts = $role->get_hosts;

    # set role params
    # TODO: move from here
    my $params = $role->params;
    for my $key (keys %$params) {
        Cinnamon::Config::set $key => $params->{$key};
    }

    return $hosts;
}

sub add_task {
    my ($self, $name, $code) = @_;
    unless (ref $code eq 'HASH') {
        my $task = Cinnamon::Task->new(
            name => $name,
            code => $code,
        );
        return $self->tasks->set($name => $task);
    }

    # a nest task is named as joined by colon
    for my $child (keys %$code) {
        my $child_name = join ":", $name, $child;
        $self->add_task($child_name => $code->{$child});
    }
}

sub get_task {
    my ($self, $name) = @_;
    return $self->tasks->get($name);
}

sub dump_info {
    my ($self) = @_;
    my $info = {};

    my $roles = $self->roles;
    my $role_info = +{
        map { $_->name => $_->info } $roles->values,
    };

    my $tasks = $self->tasks;
    my $task_info = +{
        map { $_->name => $_->code } $tasks->values,
    };

    log 'info', YAML::Dump({
        roles => $role_info,
        tasks => $task_info,
    });
}

!!1;
