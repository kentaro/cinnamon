requires 'AnyEvent';
requires 'Class::Load';
requires 'Coro';
requires 'Getopt::Long';
requires 'IPC::Run';
requires 'Log::Dispatch';
requires 'Net::OpenSSH';
requires 'POSIX';
requires 'Term::ANSIColor';
requires 'Term::ReadKey';
requires 'YAML';
requires 'Moo';
requires 'Hash::MultiValue';
requires 'parent';
requires 'perl', '5.014002';

on build => sub {
    requires 'Capture::Tiny';
    requires 'Cwd::Guard';
    requires 'Directory::Scratch';
    requires 'Test::Class';
    requires 'Test::More', '0.98';
    requires 'Test::Requires';
};
