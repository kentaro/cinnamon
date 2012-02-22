use Cinnamon::Config;
use Cinnamon::Function;

my $application = 'Cinnamon::App';

set application => $application;
set repository  => "git://repository.admin.h/projects/$application";
set deploy_to   => "/home/httpd/apps/$application";

role development => sub {
    'development.host'
};

task development => update => sub {
    my ($host, @args) = @_;

    ssh {
        run 'pwd';
    } $host;
};

role production => sub {
    'production.host'
};

task production => update => sub {
    my ($host, @args) = @_;

    ssh {
        run 'pwd';
    } $host;
};
