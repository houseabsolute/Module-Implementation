use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use Test::Spelling; 1" or (
        $ENV{RELEASE_TESTING}
            ? die ('Required release-testing module Test::Spelling is missing')
            : plan skip_all => 'Test::Spelling required for this test'
    );
}

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;
}

add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');

# This prevents a weird segfault from the aspell command - see
# https://bugs.launchpad.net/ubuntu/+source/aspell/+bug/71322
local $ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok;

__DATA__
API
PurePerl
Rolsky
env
namespace
namespaces
