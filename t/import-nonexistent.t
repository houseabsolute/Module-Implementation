use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal 0.006;

{
    package T;

    use strict;
    use warnings;

    use lib 't/lib';

    use Module::Implementation;

    for my $sigil (qw( $ @ % & )) {

        my $sym = $sigil . 'nonexistent';

        my $loader = Module::Implementation::build_loader_sub(
            implementations => ['Impl1'],
            symbols         => [$sym],
        );

        Test::Builder->new->todo_start(
            'Perhaps we should consider undefined scalars ineligible for import...'
        ) if $sigil eq '$';

        ::like(
            ::exception { $loader->() } || '',
            qr/\QCan't copy nonexistent symbol $sym from T::Impl1 to T/,
            "Got an exception on copy of non-existent symbol $sym",
        );

        Test::Builder->new->todo_end
            if $sigil eq '$';
    }
}

done_testing();
