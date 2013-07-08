package T::Impl1;

use strict;
use warnings;

sub return_42 {
    return 42;
}

sub return_package {
    return __PACKAGE__;
}

sub only_in_impl1 {
    return 69;
}

our $SCALAR = 42;
our @ARRAY  = ( 1, 2, 3 );
our %HASH   = ( key => 'val' );

open MULTI, '>&STDOUT' or die 'Unable to dup STDOUT';
our (%MULTI, @MULTI);

1;
