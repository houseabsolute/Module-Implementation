package T::Impl2;

use strict;
use warnings;

sub return_42 {
    return 42;
}

sub return_package {
    return __PACKAGE__;
}

our $SCALAR = 42;
our @ARRAY  = ( 1, 2, 3 );
our %HASH   = ( key => 'val' );

open MULTI, '>&STDOUT' or die 'Unable to dup STDOUT';
our (%MULTI, @MULTI);

1;
