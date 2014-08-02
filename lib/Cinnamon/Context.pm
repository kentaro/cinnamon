package Cinnamon::Context;
use strict;
use warnings;

use Moo;

use YAML ();
use Class::Load ();
use Hash::MultiValue;
use Term::ReadKey;

use Cinnamon;
use Cinnamon::Runner;
use Cinnamon::Logger;
use Cinnamon::Role;
use Cinnamon::Task;
use Cinnamon::Config::Loader;

our $CTX;

has roles => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has tasks => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has params => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

sub run {
    my ($self, $role_name, $task_name, %opts)  = @_;

    Cinnamon::Config::Loader->load(config => $opts{config});

    if ($opts{info}) {
        $self->dump_info;
        return;
    }

    # set role name and task name
    CTX->set_param(role => $role_name);
    CTX->set_param(task => $task_name);

    # override setting
    for my $key (keys %{ $opts{override_settings} }) {
        CTX->set_param($key => $opts{override_settings}->{$key});
    }

    my $hosts  = $self->get_role_hosts($role_name);
    my $task   = $self->get_task($task_name);
    my $runner = $self->get_param('runner_class') || 'Cinnamon::Runner';

    unless (defined $hosts) {
        log 'error', "undefined role : '$role_name'";
        return;
    }
    unless (defined $task) {
        log 'error', "undefined task : '$task_name'";
        return;
    }

    Class::Load::load_class $runner;

    my $result = $runner->start($hosts, $task);
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
        $self->set_param($key => $params->{$key});
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

sub set_param {
    my ($self, $key, $value) = @_;
    $self->params->set($key => $value);
}

sub get_param {
    my ($self, $key, @args) = @_;

    my $value = $self->params->get($key);
    $value = $value->(@args) if ref $value eq 'CODE';

    return $value;
}

# Thread-specific stash
sub stash {
    my $stash = $Coro::current->{Cinnamon} ||= {};
}

sub call_task {
    my ($self, $task_name, $host) = @_;
    my $task = $self->get_task($task_name) or die "undefined task : '$task_name'";

    $task->execute($host);
}

sub run_cmd {
    my ($self, $commands, $opts) = @_;
    $opts ||= {};

    my $current_host = $self->stash->{current_host} || 'localhost';
    log info => sprintf "[%s :: executing] %s", $current_host, join(' ', @$commands);

    if ($opts->{sudo}) {
        $opts->{password} = $self->_get_sudo_password();
    }

    $opts->{tty} = !! $self->get_param('tty');

    my $executor = $self->build_command_executor;
    my $result = $executor->execute($commands, $opts);

    if ($result->{has_error}) {
        die sprintf "error status: %d", $result->{error};
    }

    return ($result->{stdout}, $result->{stderr});
}

sub build_command_executor {
    my ($self) = @_;

    if (my $remote = $self->stash->{current_remote}) {
        return $remote;
    }
    else {
        return Cinnamon::Local->new;
    }
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
        map { %{ $_->info } } $tasks->values,
    };

    log 'info', YAML::Dump({
        roles => $role_info,
        tasks => $task_info,
    });
}

sub _get_sudo_password {
    my ($self) = @_;
    my $password = $self->get_param('password');
    return $password if defined $password;

    print "Enter sudo password: ";
    ReadMode "noecho";
    chomp($password = ReadLine 0);
    ReadMode 0;
    print "\n";

    $self->set_param(password => $password);
    return $password;
}

!!1;
