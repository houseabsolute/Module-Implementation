use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    Module::Implementation::setup_import_sub(
        implementations => [ 'ImplFails1', 'ImplFails2' ],
        symbols         => [qw( return_42 )],
    );

    ::like(
        ::exception{ __PACKAGE__->import() },
        qr/Could not find a suitable T implementation/,
        'Got an exception when all implementations fail to load'
    );
}

done_testing;
