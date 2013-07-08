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
        symbols => [qw( return_42 &return_package $SCALAR @ARRAY %HASH *MULTI ),
          qr/_6$/,
          qr/^perl_.+[^6]$/,
        ],
    );

    $loader->();
}

{
    ok( T->can('return_42'),      'T package has a return_42 sub' );
    ok( T->can('return_package'), 'T package has a return_package sub' );
    is( T::return_42(), 42, 'T::return_42 work as expected' );
    is(
        T::return_package(),
        'T::Impl1',
        'T::return_package returns implementation package'
    );

    ok( T->can('perl_5_6'), 'T package did import perl_5_6 (1st re)' );
    ok( T->can('perl_5_8'), 'T package did import perl_5_8 (2nd re)' );
    ok( T->can('perl_5_10'),'T package did import perl_5_10 (2nd re)' );
    ok( T->can('perl_5_14'),'T package did import perl_5_14 (2nd re)' );
    ok(!T->can('perl_5_16'),'T package did not import perl_5_16 (2nd re)' );

    no warnings 'once';
    is( $T::SCALAR, 42, '$T::SCALAR was copied from implementation' );
    is_deeply(
        \@T::ARRAY,
        [ 1, 2, 3 ],
        '@T::ARRAY was copied from implementation'
    );
    is_deeply(
        \%T::HASH,
        { key => 'val' },
        '%T::HASH was copied from implementation'
    );

    for my $slot (qw( IO ARRAY HASH )) {
        is(
            *T::MULTI{$slot},
            *T::Impl1::MULTI{$slot},
            "$slot slot properly copied on import",
        );
    }

    is( fileno(T::MULTI), fileno(T::Impl1::MULTI), 'MULTI IO slot imported' );
    is( \@T::MULTI, \@T::Impl1::MULTI, 'MULTI fresh ARRAY slot aliased' );
    is( \%T::MULTI, \%T::Impl1::MULTI, 'MULTI fresh HASH slot aliased' );

    ok( ! T->can('MULTI'),  'MULTI CODE slot not autovivified' );


    ok( ! defined $T::perl_5_6, '$T::perl_5_6 not copied from implementation' );
    is_deeply(
        \@T::perl_5_6,
        [ ],
        '@T::perl_5_6 not copied from implementation'
    );
    is_deeply(
        \%T::perl_5_6,
        { },
        '%T::perl_5_6 not copied from implementation'
    );
}

done_testing();
