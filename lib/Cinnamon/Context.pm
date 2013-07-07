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

our $CTX;

has roles => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

sub run {
    my ($self, $role, $task, %opts)  = @_;
    Cinnamon::Config::load $role, $task, %opts;

    if ($opts{info}) {
        $self->dump_info;
        return;
    }

    my $hosts    = $self->get_role_hosts($role);
    my $task_def = Cinnamon::Config::get_task;
    my $runner   = Cinnamon::Config::get('runner_class') || 'Cinnamon::Runner';

    unless (defined $hosts) {
        log 'error', "undefined role : '$role'";
        return;
    }
    unless (defined $task_def) {
        log 'error', "undefined task : '$task'";
        return;
    }

    Class::Load::load_class $runner;

    my $result = $runner->start($hosts, $task_def);
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

sub dump_info {
    my ($self) = @_;
    my $info = Cinnamon::Config::info;

    my $roles = $self->roles;
    my $role_info = {};
    for my $name ($roles->keys) {
        $role_info->{$name} = $roles->get($name)->info;
    }

    $info->{roles} = $role_info;
    log 'info', YAML::Dump($info);
}

!!1;
