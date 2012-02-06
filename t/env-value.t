use strict;
use warnings;

use Test::More 0.88;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    Module::Implementation::setup_import_sub(
        implementations => [ 'Impl1', 'Impl2' ],
        symbols         => ['return_42'],
    );

    $ENV{T_IMPLEMENTATION} = 'Impl2';

    __PACKAGE__->import();
}

{
    ok( T->can('return_42'), 'T package has a return_42 sub' );
    ok(
        !T->can('return_package'),
        'T package does not have return_package sub - only copied requested symbols'
    );
    is( T::return_42(), 42, 'T::return_42 work as expected' );
    is( T::_implementation(), 'Impl2', 'T::_implementation returns implementation set in ENV' );
}

done_testing;
