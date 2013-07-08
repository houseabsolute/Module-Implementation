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
    my $loader = Module::Implementation::build_loader_sub(
        implementations => [ 'Impl1', 'Impl2' ],
        symbols         => [qw( only_in_impl1 )],
    );

    ::like(
        ::exception{ $loader->() },
        qr/\QSymbol import mismatch - &only_in_impl1 does not exist in alternative implementation(s): T::Impl2/,
        'Got an exception when requested symbol is not present in all implementations'
    );
}

done_testing();
