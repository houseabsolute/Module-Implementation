package Module::Implementation;

use strict;
use warnings;

use Module::Runtime 0.011 qw( require_module );
use Try::Tiny;

sub setup_import_sub {
    my $caller = caller();

    my $loader = _build_loader( $caller, @_ );
    no strict 'refs';
    *{ $caller . '::import' } = $loader;

    return;
}

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
            my $loaded = "${package}::$possible";

            my $ok;
            try {
                require_module($loaded);
                $ok = 1;
            }
            catch {
                $err .= $_;
            };

            return ( $possible, $loaded ) if $ok;
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
