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

        'Term::ANSIColor',
        'IPC::Run',
        'Net::OpenSSH',
        'Log::Dispatch',
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
