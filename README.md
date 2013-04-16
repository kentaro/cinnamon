# NAME

Cinnamon - A minimalistic deploy tool

# SYNOPSIS

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
        my ($host, @args) = @_;
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
      my ($host, @args) = @_;
      # ...
    };

    # Nest tasks
    task server => {
        setup => sub {
            my ($host, @args) = @_;
            # ...
        },
    };

# WARNINGS

This software is under the heavy development and considered ALPHA quality.  Things might be broken, not all features have been implemented, and APIs will be likely to change.

# DESCRIPTION

Cinnamon is a minimalistic deploy tool aiming to provide
structurization of issues about deployment. It only introduces the
most essential feature for deployment and a few utilities.

# DSLs

This module provides some DSLs for use. I designed them to be kept as
simple as possible, and I don't want to add too many commands:

## Structural Commands

### role ( _$role: Str_ => (_$host: String_ | _$hosts: Array\[String\]_ | _$sub: CODE_), _$param: HASHREF_ )

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

### task ( _$taskname: Str_ => (_\\%tasks: Hash\[String =_ CODE\]> | _$sub: CODE_) )

        task update => sub {
            my ($host, @args) = @_;
            my $hoge = get 'hoge'; # parameter set in global or role parameter
            # ...
        };

        # you can nest tasks
        task server => {
            start => sub {
              my ($host, @args) = @_;
              # ...
            },
            stop => sub {
              my ($host, @args) = @_;
              # ...
            },
        };

    Defines some named tasks by CODEs.

    The arguments which are passed into the CODEs are:

    - _$host_

        The host name where the task is executed. Which is one of the hosts
        you set by `role` command.

    - _@args_

        Command line argument which is passed by user.

            $ cinammon production update foo bar baz

        In case above, `@args` contains `('foo', 'bar', 'baz')`.

## Utilities

### set ( _$key: String_ => (_$value: Any_ | _$sub: CODE_) )

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
    value to be evaluated till `get` is called. This is useful when you
    want to retrieve hosts information from some external APIs or so.

### get ( _$key: String_ \[, _@args: Array\[Any\]_ \] ): Any

        my $value = get 'key';

        # or

        my $value = get key => qw(foo bar baz);

    Gets a value related to the key.

    If the value is a CODE, you can pass some arguments which can be used
    while evaluating.

### run ( _@command: Array_ ): ( _$stdout: String_, _$stderr: String_ )

        my ($stdout, $stdout) = run 'git', 'pull';

    Executes a command. It returns the result of execution, `$stdout` and
    `$stderr`, as strings.

### sudo ( _@command: Array_ ): ( _$stdout: String_, _$stderr: String_ )

        my ($stdout, $stdout) = sudo '/path/to/httpd', 'restart';

    Executes a command as well, but under _sudo_ environment.

### remote ( _$sub: CODE_ _$host: String_ ): Any

        my ($stdout, $stdout) = remote {
            run  'git', 'pull';
            sudo '/path/to/httpd', 'restart';
        } $host;

Connects to the remote `$host` and executes the `$code` there.

Where `run` and `sudo` commands to be executed depends on that
context. They are done on the remote host when set in `remote` block,
whereas done on localhost without it.

Remote login username is retrieved by `get 'user'` or ``whoami``
command. Set appropriate username in advance if needed.

## Configuration Variables

Cinnamon configuration is managed by set function.  You can customize following variables.

### user

user name which is used for login to server.

### concurrency

Max number of concurrent execution of tasks.  the task which is not specified concurrency, is executed in parallel by all the hosts.

        set concurrency => {
            restart        => 1,
            'server:setup' => 2,
        };

# REPOSITORY

https://github.com/kentaro/cinnamon

# AUTHOR

- Kentaro Kuribayashi <kentarok@gmail.com>
- Yuki Shibazaki <shibayu36 at gmail.com>

# SEE ALSO

- Tutorial (Japanese)

    [http://d.hatena.ne.jp/naoya/20130118/1358477523](http://d.hatena.ne.jp/naoya/20130118/1358477523)

- [capistrano](http://search.cpan.org/perldoc?capistrano)
- [Archer](http://search.cpan.org/perldoc?Archer)

# LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
