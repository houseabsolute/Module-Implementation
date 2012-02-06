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
        implementations => [ 'ImplFails1', 'Impl1' ],
        symbols         => [qw( return_42 )],
    );

    __PACKAGE__->import();
}

{
    ok( T->can('return_42'),       'T package has a return_42 sub' );
    ok( !T->can('return_package'), 'T package has a return_package sub' );
}

done_testing;
