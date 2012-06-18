use strict;
use warnings;
use Test::More skip_all => 'TODO';

use Net::OpenSSH;

use Cinnamon::Remote;

no strict 'refs';
no warnings 'redefine';
local *Net::OpenSSH::new = sub {
    my ($class, $host, %args) = @_;
    bless {}, $class;
};

subtest 'run success' => sub {
    local *Net::OpenSSH::capture2 = sub {
        my ($self, $cmd) = @_;
        return ($cmd, $cmd);
    };
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    my $res = $remote->execute({}, "ls", "/");
    is $res->{stdout}, "ls /";
    is $res->{stderr}, "ls /";
    ok !$res->{has_error};
    is $res->{error}, undef;
};

subtest 'run failure' => sub {
    local *Net::OpenSSH::capture2 = sub {
        my ($self, $cmd) = @_;
        return ($cmd, $cmd);
    };
    local *Net::OpenSSH::error = sub { 'error' };
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    $remote->connection->error('error');
    my $res = $remote->execute({}, "ls", "/");
    is $res->{stdout}, "ls /";
    is $res->{stderr}, "ls /";
    ok $res->{has_error};
    is $res->{error}, 'error';
};

subtest 'sudo run success' => sub {
    local *Net::OpenSSH::capture2 = sub {
        my ($self, $opt, $cmd) = @_;
        return ($cmd, $opt);
    };
    my $remote = Cinnamon::Remote->new(host => 'localhost', user => 'app');
    $remote->connection->error('error');
    my $res = $remote->execute({sudo => 1, password => 'password'}, "ls", "/");
    is $res->{stdout}, "sudo -Sk ls /";
    is $res->{stderr}->{stdin_data}, "password\n";
    ok !$res->{has_error};
};

done_testing();
