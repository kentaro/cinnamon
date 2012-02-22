use Cinnamon::Config;
use Cinnamon::Function;

my $application = 'Cinnamon::App';

set application => $application;
set repository  => "git://repository.admin.h/projects/$application";
set deploy_to   => "/home/httpd/apps/$application";

role development => sub {
    'develpment.h'
};

task development => {
    update => sub {
        my ($host, @args) = @_;

        ssh {
            print run 'pwd';
        } $host;
    },

    start => sub {
        my ($host, @args) = @_;
        # ...
    },
};

role production => sub {
    'production.host'
};

task development => {
    update => sub {
        my ($host, @args) = @_;

        ssh {
            print run 'pwd';
        } $host;
    },

    start => sub {
        my ($host, @args) = @_;
        # ...
    },
};
