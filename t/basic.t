use strict;
use warnings;

use Test::More 0.88;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'Impl1', 'Impl2' ],
        symbols         => ['return_42'],
    );

    $loader->();
}

{
    ok( T->can('return_42'), 'T package has a return_42 sub' );
    ok(
        !T->can('return_package'),
        'T package does not have return_package sub - only copied requested symbols'
    );
    is( T::return_42(), 42, 'T::return_42 work as expected' );
    is( T::_implementation(), 'Impl1', 'T::_implementation returns default implementation' );
}

done_testing();
