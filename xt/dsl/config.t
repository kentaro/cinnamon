use strict;
use warnings;
use Test::More;
use Cwd;

use xt::Cinnamon;

{
    my $app = cinnamon();
    $app->dir->touch("config/deploy.pl", <<EOF);
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task echo_user => sub {
    print(get 'user');
};
EOF
    $app->run("cinnamon test echo_user");
    $app->system_output;

    is $app->system_output, 'app';
}

done_testing;
