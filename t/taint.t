#!perl -T

use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal 0.006;

BEGIN {
    eval "use Test::Taint; 1"
        or plan skip_all => "Test requires module 'Test::Taint' but it's not found"
}

taint_checking_ok();

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

    ::taint( $ENV{T_IMPLEMENTATION} = 'Impl2' );

    ::tainted_ok( $ENV{T_IMPLEMENTATION}, '$ENV{T_IMPLEMENTATION} is tainted' );

    ::is(
        ::exception{ $loader->() },
        undef,
        'no exception when implementation is specified in env var under taint mode'
    );
}

{
    is(
        Module::Implementation::implementation_for('T'),
        'Impl2',
        'T::_implementation returns implementation set in ENV'
    );
}

done_testing();
