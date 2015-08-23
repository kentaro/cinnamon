package Cinnamon;
use strict;
use warnings;
use 5.010_001;

use parent qw(Exporter);

our $VERSION = '0.28';

our @EXPORT = qw(CTX);
sub CTX { $Cinnamon::Context::CTX };

!!1;

__END__

=encoding utf8

=head1 NAME

Cinnamon - A minimalistic deploy tool

=head1 SYNOPSIS

  use strict;
  use warnings;

  # Exports some commands
  use Cinnamon::DSL;

  my $application = 'My::App';

  # It's required if you want to login to remote host
  set user => 'johndoe';

  # User defined params to use later
  set application => $application;
  set repository  => "git://git.example.com/projects/$application";

  # Lazily evaluated if passed as a code
  set lazy_value  => sub {
      #...
  };

  # Roles
  role development => 'development.example.com', {
      deploy_to => "/home/app/www/$application-devel",
      branch    => "develop",
  };

  # Lazily evaluated if passed as a code
  role production  => sub {
      my $res   = LWP::UserAgent->get('http://servers.example.com/api/hosts');
      my $hosts = decode_json $res->content;
         $hosts;
  }, {
      deploy_to => "/home/app/www/$application",
      branch    => "master",
  };

  # Tasks
  task update => sub {
      my ($host) = @_;
      my $deploy_to = get('deploy_to');
      my $branch = 'origin/' . get('branch');

      # Executed on localhost
      run 'some', 'command';

      # Executed on remote host
      remote {
          run "cd $deploy_to && git fetch origin && git checkout -q $branch && git submodule update --init";
      } $host;
  };
  task restart => sub {
    my ($host) = @_;
    # ...
  };

  # Nest tasks
  task server => {
      setup => sub {
          my ($host) = @_;
          # ...
      },
  };

  # You can call other tasks
  task deploy => sub {
    my ($host) = @_;
    call "update", $host;
    call "restart", $host;
  };

=head1 WARNINGS

This software is under the heavy development and considered ALPHA quality.  Things might be broken, not all features have been implemented, and APIs will be likely to change.

=head1 DESCRIPTION

Cinnamon is a minimalistic deploy tool aiming to provide
structurization of issues about deployment. It only introduces the
most essential feature for deployment and a few utilities.

=head1 DSLs

This module provides some DSLs for use. I designed them to be kept as
simple as possible, and I don't want to add too many commands:

=head2 Structural Commands

=head3 role ( I<$role: Str> => (I<$host: String> | I<$hosts: Array[String]> | I<$sub: CODE>), I<$param: HASHREF> )

=over 4

  role production => 'production.example.com';

  # or

  role production => [ qw(production1.example.com production2.exampl.ecom) ];

   # or

  role production => sub {
      my $res   = LWP::UserAgent->get('http://servers.example.com/api/hosts');
      my $hosts = decode_json $res->content;
         $hosts;
  };

  # or

  role production => 'production.example.com', {
      hoge => 'fuga',
  };

Relates names (eg. production) to hosts to be deployed.

If you pass a CODE as the second argument, this method delays the
value to be evaluated till the value is needed at the first time. This
is useful, for instance, when you want to retrieve hosts information
from some external APIs or so.

If you pass a HASHREF as the third argument, you can get specified
parameters by get DSL.

=back

=head3 task ( I<$taskname: Str> => (I<\%tasks: Hash[String => CODE]> | I<$sub: CODE>) )

  task update => sub {
      my ($host) = @_;
      my $hoge = get 'hoge'; # parameter set in global or role parameter
      # ...
  };

  # you can nest tasks
  task server => {
      start => sub {
        my ($host) = @_;
        # ...
      },
      stop => sub {
        my ($host) = @_;
        # ...
      },
  };

Defines some named tasks by CODEs.

The arguments which are passed into the CODEs are:

=over 4

=item * I<$host>

The host name where the task is executed. Which is one of the hosts
you set by C<role> command.

=back

=head2 Utilities

=head3 set ( I<$key: String> => (I<$value: Any> | I<$sub: CODE>) )

=over 4

  set key => 'value';

  # or

  set key => sub {
      # values to be lazily evaluated
  };

  # or

  set key => sub {
      my (@args) = @_;
      # value to be lazily evaluated with @args
  };

Sets a value which is related to a key.

If you pass a CODE as the second argument, this method delays the
value to be evaluated till C<get> is called. This is useful when you
want to retrieve hosts information from some external APIs or so.

=back

=head3 get ( I<$key: String> [, I<@args: Array[Any]> ] ): Any

=over 4

  my $value = get 'key';

  # or

  my $value = get key => qw(foo bar baz);

Gets a value related to the key.

If the value is a CODE, you can pass some arguments which can be used
while evaluating.

=back

=head3 run ( I<@command: Array> ): ( I<$stdout: String>, I<$stderr: String> )

=over 4

  my ($stdout, $stdout) = run 'git', 'pull';

Executes a command. It returns the result of execution, C<$stdout> and
C<$stderr>, as strings.

=back

=head3 sudo ( I<@command: Array> ): ( I<$stdout: String>, I<$stderr: String> )

=over 4

  my ($stdout, $stdout) = sudo '/path/to/httpd', 'restart';

Executes a command as well, but under I<sudo> environment.

=back

=head3 remote ( I<$sub: CODE> I<$host: String> ): Any

=over 4

  my ($stdout, $stdout) = remote {
      run  'git', 'pull';
      sudo '/path/to/httpd', 'restart';
  } $host;

=back

Connects to the remote C<$host> and executes the C<$code> there.

Where C<run> and C<sudo> commands to be executed depends on that
context. They are done on the remote host when set in C<remote> block,
whereas done on localhost without it.

Remote login username is retrieved by C<get 'user'> or C<`whoami`>
command. Set appropriate username in advance if needed.

=head3 call ( I<$task_name: String>, I<$host: String> )

=over 4

  task deploy => sub {
    my ($host) = @_;
    call "update", $host;
    call "web:restart", $host;
  };

=back

Call other tasks in a task code.

=head2 Configuration Variables

Cinnamon configuration is managed by set function.  You can customize following variables.

=head3 user

user name which is used for login to server.

=head3 concurrency

Max number of concurrent execution of tasks.  the task which is not specified concurrency, is executed in parallel by all the hosts.

=over 4

    set concurrency => {
        restart        => 1,
        'server:setup' => 2,
    };

=back

=head1 REPOSITORY

https://github.com/kentaro/cinnamon

=head1 AUTHOR

=over 4

=item * Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=item * Yuki Shibazaki E<lt>shibayu36 at gmail.comE<gt>

=back

=head1 SEE ALSO

=over 4

=item * Tutorial (Japanese)

L<http://d.hatena.ne.jp/naoya/20130118/1358477523>

=item * L<capistrano>

=item * L<Archer>

=back

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
