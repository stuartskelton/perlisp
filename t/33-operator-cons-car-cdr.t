#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 21;

use PerLisp;

my $pl = PerLisp->new->init;

# cons the empty list
my $empty = $pl->eval('(cons)');
is_deeply($empty->to_simple, [], 'empty list simplification');
is($empty->to_string, '()', 'empty list stringification');
my $car = $pl->eval('(car (cons))');
ok(! defined $car, 'empty list car');
my $cdr = $pl->eval('(cdr (cons))');
isa_ok($cdr, 'PerLisp::Expr::List', 'empty list cdr');
is_deeply($cdr->to_simple, [], 'empty list cdr simplification');
is($cdr->to_string, '()', 'empty list cdr stringification');

# cons a one element list
$pl->eval('(bind foo (cons 42))');
my $list = $pl->context->get('foo');
is_deeply($list->to_simple, [42], 'one element list simplification');
is($list->to_string, '(42)', 'one element list stringification');
$car = $pl->eval('(car foo)');
isa_ok($car, 'PerLisp::Expr::Number', 'one element list car');
is($car->to_simple, 42, 'one element list car simplification');
$cdr = $pl->eval('(cdr foo)');
isa_ok($cdr, 'PerLisp::Expr::List', 'one element list cdr');
is_deeply($cdr->to_simple, [], 'one element list cdr simplification');

# cons one element and the one element list to a two element list
$pl->eval('(bind bar (cons 17 foo))');
$list = $pl->context->get('bar');
is_deeply($list->to_simple, [17, 42], 'two element list simplification');
is($list->to_string, '(17 42)', 'two element list stringification');
$car = $pl->eval('(car bar)');
isa_ok($car, 'PerLisp::Expr::Number', 'two element list car');
is($car->to_simple, 17, 'two element list car simplification');
$cdr = $pl->eval('(cdr bar)');
isa_ok($cdr, 'PerLisp::Expr::List', 'two element list cdr');
is_deeply($cdr->to_simple, [42], 'two element list cdr simplification');
my $cddr = $pl->eval('(cdr (cdr bar))');
isa_ok($cddr, 'PerLisp::Expr::List', 'two element list cdr cdr');
is_deeply($cddr->to_simple, [], 'two element list cddr simplification');
is($cddr->to_string, '()', 'two element list cddr stringification');

__END__
