use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    license              => 'perl',
    dynamic_config       => 0,

    build_requires       => {
        'Test::More' => '0.98',
        'Test::Requires' => 0,
    },
    configure_requires   => { 'Module::Build' => '0.38' },
    requires             => {
        perl   => "$]",
        parent => '0',

        'Term::ANSIColor'      => 0,
        'IPC::Run'             => 0,
        'Net::OpenSSH'         => 0,
        'Log::Dispatch'        => 0,
        'Class::Load'          => 0,
        'Term::ReadKey'        => 0,
        'Getopt::Long::Parser' => 0,
        'AnyEvent'             => 0,
        'POSIX'                => 0,
    },
    build_requires       => {
        'Directory::Scratch' => 0,
        'Capture::Tiny'      => 0,
        'Test::More'         => 0,
        'Test::Class'        => 0,
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
$build->meta_add({
    resources => {
        X_prepan => {
            module_url => 'http://prepan.org/module/xxxxx',
            author_url => 'http://prepan.org/user/xxxxxxx',
        },
    },
});
$build->create_build_script();
