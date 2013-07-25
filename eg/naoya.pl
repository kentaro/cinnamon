# config/deploy.pl
# See http://d.hatena.ne.jp/naoya/20130118/1358477523
use strict;
use warnings;
use Cinnamon::DSL;

set application => 'myapp';
set repository  => 'git@github.com:naoya/myapp.git';
set user        => 'fiorung';
set password    => '';

role development => ['myapp-development.ap-northeast-1'], {
    deploy_to   => '/home/fiorung/apps/myapp',
    branch      => 'master',
};

task deploy  => {
    setup => sub {
        my ($host) = @_;
        my $repository = get('repository');
        my $deploy_to  = get('deploy_to');
        my $branch   = 'origin/' . get('branch');
        remote {
            run "git clone $repository $deploy_to && git checkout -q $branch";
        } $host;
    },
    update => sub {
        my ($host) = @_;
        my $deploy_to = get('deploy_to');
        my $branch   = 'origin/' . get('branch');
        remote {
            run "cd $deploy_to && git fetch origin && git checkout -q $branch && git submodule update --init";
        } $host;
    },
};

task server => {
    start => sub {
        my ($host) = @_;
        remote {
            sudo "supervisorctl start myapp";
        } $host;
    },
    stop => sub {
        my ($host) = @_;
        remote {
            sudo "supervisorctl stop myapp";
        } $host;
    },
    restart => sub {
        my ($host) = @_;
        remote {
            run "kill -HUP `cat /tmp/myapp.pid`";
        } $host;
    },
    status => sub {
        my ($host) = @_;
        remote {
            sudo "supervisorctl status";
        } $host;
    },
};

task carton => {
    install => sub {
        my ($host) = @_;
        my $deploy_to = get('deploy_to');
        remote {
            run ". ~/perl5/perlbrew/etc/bashrc && cd $deploy_to && carton install";
        } $host;
    },
};
