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
        implementations => [ 'ImplFails1', 'Impl1' ],
        symbols         => [qw( return_42 )],
    );

    $ENV{T_IMPLEMENTATION} = 'ImplFails1';

    ::like(
        ::exception{ __PACKAGE__->import() },
        qr/Could not load T::ImplFails1/,
        'Got an exception when implementation requested in env value fails to load'
    );
}

done_testing;
