use strict;
use warnings;
use LWP::UserAgent;

# Exports some commands
use Cinnamon::DSL;

my $application = 'My::App';

# It's required if you want to login to remote host
set user => 'johndoe';

# User defined params to use later
set application => $application;
set repository  => "git://git.example.com/projects/$application";
set deploy_to   => "/home/app/www/$application";

# Lazily evaluated if passed as a code
set lazy_value  => sub {
    #...
};

# Roles
role development => 'development.example.com';
role test => 'test.example.com', {
    deploy_to => "/home/app/www/$application-Test",
    hoge      => 'fuga',
};

# Lazily evaluated if passed as a code
role production  => sub {
    my $res   = LWP::UserAgent->new->get('http://servers.example.com/api/hosts');
    my $hosts = decode_json $res->content;
       $hosts;
};

# Tasks
task update => sub {
    my ($host) = @_;

    # Executed on localhost
    run 'some', 'command';

    # Executed on remote host
    remote {
        run  'git', 'pull';
        sudo '/path/to/httpd', 'restart';
    } $host;
};

# nest tasks
task server => {
    setup => sub {
        my ($host) = @_;

        # Executed on localhost
        run 'some', 'command';

        # Executed on remote host
        my ($stdout, $stderr) = remote {
            run  'git', 'pull';
            sudo '/path/to/httpd', 'restart';
        } $host;

        # Do something with the return values
        My::IRC::Client->new->send('#deploy', "Updated: $stdout, $stderr");
    },

    restart => sub {
        my ($host) = @_;
        # ...
    },
};
