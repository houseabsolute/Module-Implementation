package Module::Implementation;

use strict;
use warnings;

use Module::Runtime 0.011 qw( require_module );
use Try::Tiny;

sub build_loader_sub {
    my $caller = caller();

    return _build_loader( $caller, @_ );
}

sub _build_loader {
    my $package = shift;
    my %args    = @_;

    my @implementations = @{ $args{implementations} };
    my @symbols = @{ $args{symbols} || [] };

    my $implementation;
    my $env_var = uc $package;
    $env_var =~ s/::/_/g;
    $env_var .= '_IMPLEMENTATION';

    return sub {
        my ( $implementation, $loaded ) = _load_implementation(
            $package,
            $ENV{$env_var},
            \@implementations,
        );

        _copy_symbols( $loaded, $package, \@symbols );

        my $impl_sub = sub {
            return $implementation;
        };

        {
            no strict 'refs';
            *{ $package . '::_implementation' } = $impl_sub;
        }

        return;
    };
}

sub _load_implementation {
    my $package         = shift;
    my $env_value       = shift;
    my $implementations = shift;

    if ($env_value) {
        die "$env_value is not a valid implementation for $package"
            unless grep { $_ eq $env_value } @{$implementations};

        my $loaded = "${package}::$env_value";

        # Values from the %ENV hash are tainted. We know it's safe to untaint
        # this value because the value was one of our known implementations.
        ($loaded) = $loaded =~ /^(.+)$/;

        try {
            require_module($loaded);
        }
        catch {
            require Carp;
            Carp::croak("Could not load $loaded: $_");
        };

        return ( $env_value, $loaded );
    }
    else {
        my $err;
        for my $possible ( @{$implementations} ) {
            my $load = "${package}::$possible";

            my $ok;
            try {
                require_module($load);
                $ok = 1;
            }
            catch {
                $err .= $_;
            };

            return ( $possible, $load ) if $ok;
        }

        require Carp;
        Carp::croak(
            "Could not find a suitable $package implementation: $err");
    }
}

sub _copy_symbols {
    my $from_package = shift;
    my $to_package   = shift;
    my $symbols      = shift;

    for my $sym ( @{$symbols} ) {
        my $type = $sym =~ s/^([\$\@\%\&\*])// ? $1 : '&';

        my $from = "${from_package}::$sym";
        my $to   = "${to_package}::$sym";

        {
            no strict 'refs';
            no warnings 'once';

            # Copied from Exporter
            *{$to}
                = $type eq '&' ? \&{$from}
                : $type eq '$' ? \${$from}
                : $type eq '@' ? \@{$from}
                : $type eq '%' ? \%{$from}
                : $type eq '*' ? *{$from}
                : die
                "Can't copy symbol from $from_package to $to_package: $type$sym";
        }
    }
}

1;

# ABSTRACT: Loads one of several alternate underlying implementations for a module

__END__

=head1 SYNOPSIS

  package Foo::Bar;

  use Module::Implementation;

  BEGIN {
      my $loader = Module::Implementation::build_loader_sub(
          implementations => [ 'XS',  'PurePerl' ],
          symbols         => [ 'run', 'check' ],
      );

      $loader->();
  }

  package Consumer;

  # loads the first viable implementation
  use Foo::Bar;

=head1 DESCRIPTION

This module abstracts out the process of choosing one of several underlying
implementations for a module. This can be used to provide XS and pure Perl
implementations of a module, or it could be used to load an implementation for
a given OS or any other case of needing to provide multiple implementations.

=head1 API

This module provides one subroutine, C<build_loader_sub()>, which is not
exported. It takes the following arguments.

=over 4

=item * implementations

This should be an array reference of implementation names. Each name should
correspond to a module in the caller's namespace.

In other words, using the example in the L</SYNOPSIS>, this module will look
for the C<Foo::Bar::XS> and C<Foo::Bar::PurePerl> modules will be installed

This argument is required.

=item * symbols

A list of symbols to copy from the implementation package to the calling
package.

These can be prefixed with a variable type: C<$>, C<@>, C<%>, C<&>, or
C<*)>. If no prefix is given, the symbol is assumed to be a subroutine.

This argument is optional.

=back

This subroutine I<returns> the implementation loader as a sub reference.

It is up to you to call this loader sub in your code.

I recommend that you I<do not> call this loader in an C<import()> sub. If a
caller explicitly requests no imports, your C<import()> sub will not be run at
all, which can cause weird breakage.

Instead, I recommend calling this loader in a C<BEGIN> block like you see above.

=head1 HOW THE IMPLEMENTATION LOADER WORKS

The implementation loader works like this ...

First, it checks for an C<%ENV> var specifying the implementation to load. The
env var is based on the package name which loads the implementations. The
C<::> package separator is replaced with C<_>, and made entirely
upper-case. Finally, we append "_IMPLEMENTATION" to this name.

So in our L</SYNOPSIS> example, the corresponding C<%ENV> key would be
C<FOO_BAR_IMPLEMENTATION>.

If this is set, then the loader will B<only> try to load this one
implementation. If this one implementation fails to load then loader throws an
error. This is useful for testing. You can request a specific implementation
in a test file by writing something like this:

  BEGIN { $ENV{FOO_BAR_IMPLEMENTATION} = 'XS' }
  use Foo::Bar;

If the environment variable is I<not> set, then the loader simply tries the
implementations originally passed to C<Module::Implementation>. The
implementations are tried in the order in which they were originally passed.

The loader will use the first implementation that loads without an error. It
will copy any requested symbols from this implementation.

If none of the implementations can be loaded, then the loader throws an
exception.

If an implementation is loaded successfully, the loader creates an
C<_implementation()> subroutine in the package that created the loader. This
lets you introspect the implementation for tests and other internal use.
