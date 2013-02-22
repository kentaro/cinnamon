use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_author => [
        'Yuki Shibazaki <shibayu36@gmail.com>',
        'Kentaro Kuribayashi kentarok@gmail.com',
    ],
    dist_version_from => 'lib/Cinnamon.pm',
    license              => 'perl',
    dynamic_config       => 0,

    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl   => "$]",
        parent => '0',

        'Term::ANSIColor' => 0,
        'IPC::Run'        => 0,
        'Net::OpenSSH'    => 0,
        'Log::Dispatch'   => 0,
        'Class::Load'     => 0,
        'Term::ReadKey'   => 0,
        'Getopt::Long'    => 0,
        'AnyEvent'        => 0,
        'POSIX'           => 0,
        'YAML'            => 0,
    },
    build_requires       => {
        'Directory::Scratch' => 0,
        'Cwd::Guard'         => 0,
        'Capture::Tiny'      => 0,
        'Test::More'         => 0.98,
        'Test::Class'        => 0,
        'Test::Requires'     => 0,
    },

    no_index    => { 'directory' => [ 'inc' ] },
    name        => 'Cinnamon',
    module_name => 'Cinnamon',

    # script_files => [''],

    test_files => (-d '.git' || $ENV{RELEASE_TESTING}) ? 't/ xt/' : 't/',
    recursive_test_files => 1,

    create_readme  => 1,
    create_license => 1,
);
$build->create_build_script();
