use strict;
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
my $spell_cmd;
foreach my $path (split(/:/, $ENV{PATH})) {
    -x "$path/spell"  and $spell_cmd = "spell"             and last;
    -x "$path/ispell" and $spell_cmd = "ispell -l"         and last;
    -x "$path/aspell" and $spell_cmd = "aspell list -l en" and last;
}
plan skip_all => "no spell/ispell/aspell" unless $spell_cmd;

set_spell_cmd($spell_cmd);
all_pod_files_spelling_ok('lib');
__DATA__
Kentaro Kuribayashi
Cinnamon
tokuhirom
AAJKLFJEF
GMAIL
COM
Tatsuhiko
Miyagawa
Kazuhiro
Osawa
lestrrat
typester
cho45
charsbar
coji
clouder
gunyarakun
hio_d
hirose31
ikebe
kan
kazeburo
daisuke
maki
TODO
API
URL
URI
db
TTerse
irc
org
CSS
Amon
Tokuhiro
Matsuno
Svn
svn
diff
Gosuke
Miyashita
mysqldiff
mmm
Kentaro
Kuribayashi
antipop
GitHub
