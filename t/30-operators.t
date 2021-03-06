#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 'no_plan';

use_ok('PerLisp');

my $pl = PerLisp->new->init;

my @operators = qw(
    quote
    bind bound let
    cons list car cdr
    lambda define
    cond =
    and or not
    type
    load
    + - * / ^ % < >
);

# right stringifications
foreach my $operator (@operators) {
    is(
        $pl->context->get($operator)->to_string, $operator,
        "right operator $operator stringification",
    );
}

__END__
