use strict;
use warnings;
use Test::More;
use Cwd;

use xt::Cinnamon;
use Net::OpenSSH;

{
    my $app = cinnamon();
    $app->dir->touch("config/deploy.pl", <<'EOF');
use Cinnamon::DSL;
set user => 'app';
role test => 'localhost';
task test => sub {
    my ($host, @args) = @_;
    remote {
        run "ls /";
    } $host;
}
EOF
    $app->run("cinnamon test test");
    warn $app->system_output;
    warn $app->system_error;

    # is $app->system_output, 'app';
}

done_testing;
