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

sub perl_5_6 { 5.6 }
sub perl_5_8 { 5.8 }
sub perl_5_10 { 5.10 }
sub perl_5_14 { 5.14 }
sub perl_5_16 { 5.16 }

our $perl_5_6 = 5.6;
our @perl_5_6 = ( 5.6 );
our %perl_5_6 = ( perl => 5.6 );

1;
