package PerLisp::Operators;
# not a class but a package

use strict;
use warnings;

use feature 'switch';

use PerLisp::Expr::Symbol;
use PerLisp::Expr::List;
use PerLisp::Expr::Function;
use PerLisp::Expr::Boolean;

our %short_name = (
    quote       => 'quote',
    bind_name   => 'bind',
    bound       => 'bound',
    let         => 'let',
    cons        => 'cons',
    list        => 'list',
    car         => 'car',
    cdr         => 'cdr',
    lambda      => 'lambda',
    define      => 'define',
    cond        => 'cond',
    equal       => '=',
    logical_and => 'and',
    logical_or  => 'or',
    logical_not => 'not',
    type        => 'type',
);

# quote an expression
sub _q {
    my $expr = shift;

    # quote symbol
    my $quote_symbol = PerLisp::Expr::Symbol->new(
        name => 'quote',
    );

    # build a quote operator call
    return PerLisp::Expr::List->new(
        exprs => [$quote_symbol, $expr],
    );
}

sub quote { # eval nothing
    my ($context, $expr) = @_;

    # return the expression without evaluation
    return $expr;
}

sub bind_name { # eval only second argument
    die "bind needs exactly two arguments.\n" unless @_ == 3;
    my ($context, $symbol, $expr) = @_;

    # eval
    my $value = $expr->eval($context);

    # bind
    $context->set($symbol->name => $value);

    # return the value
    return $value;
}

sub bound { # has no arguments
    my $context = shift;

    # get all names
    my @names = sort keys %{$context->binds};

    # create symbols
    my @symbols = map { PerLisp::Expr::Symbol->new(name => $_) } @names;

    return PerLisp::Expr::List->new(exprs => \@symbols);
}

sub let { # eval only the second argument
    die "bind needs exactly three arguments.\n" unless @_ == 4;
    my ($context, $symbol, $value_expr, $expr) = @_;

    # new symbol
    die "let's first argument needs to be a symbol.\n"
        unless $symbol->isa('PerLisp::Expr::Symbol');
    my $name = $symbol->name;

    # new value
    my $value = $value_expr->eval($context);

    # bind symbol to value
    my $new_context = $context->specialize({$name => $value});

    # eval the expression in the new context
    return $expr->eval($new_context);
}

sub cons { # eval both arguments
    my ($context, $car_expr, $cdr_expr) = @_;

    # construct a list
    my $list = PerLisp::Expr::List->new;

    # car handling
    if ($car_expr) {
        push @{$list->exprs}, $car_expr->eval($context);
        
        # cdr handling
        if ($cdr_expr) {
            my $cdr = $cdr_expr->eval($context);
            die "cdr must be a list.\n"
                unless $cdr->isa('PerLisp::Expr::List');
            push @{$list->exprs}, @{$cdr->exprs};
        }
    }

    # return the new list
    return $list;
}

sub list { # eval all arguments
    my ($context, @elm_exprs) = @_;

    # eval all list element expressions
    my @exprs = map { $_->eval($context) } @elm_exprs;

    # build the list
    return PerLisp::Expr::List->new(
        exprs => \@exprs,
    );
}

sub car { # eval the argument
    my ($context, $list_expr) = @_;

    # eval the list expression
    my $list = $list_expr->eval($context);

    # check listness
    die 'car can\'t be applied on non list ' . $list->to_string . "\n"
        unless $list->isa('PerLisp::Expr::List');

    # return the car
    return $list->car;
}

sub cdr { # eval the argument
    my ($context, $list_expr) = @_;

    # eval the list expression
    my $list = $list_expr->eval($context);

    # check listness
    die 'cdr can\'t be applied on non list ' . $list->to_string . "\n"
        unless $list->isa('PerLisp::Expr::List');

    # return the cdr
    return $list->cdr;
}

sub lambda { # eval nothing
    my ($context, $param_list, $body) = @_;

    # check parameter list
    die "lambda needs a parameter list.\n"
        unless $param_list->isa('PerLisp::Expr::List');

    # create parameter "list" from parameter list symbols
    my @param_names;
    foreach my $expr (@{$param_list->exprs}) {
        die 'only symbols allowed in parameter lists: '
            . $expr->to_string . "\n"
            unless $expr->isa('PerLisp::Expr::Symbol');
        push @param_names, $expr->name;
    }

    # construct a function
    return PerLisp::Expr::Function->new(
        params  => \@param_names,
        body    => $body,
        context => $context,
    );
}

sub define { # eval nothing
    my ($context, $call_list, $body) = @_;
    
    # preparations
    my $symbol     = $call_list->car;
    my $param_list = $call_list->cdr;

    # construct the function
    my $function = lambda($context, $param_list, $body);

    # bind
    bind_name($context, $symbol, $function);

    # return the function
    return $function;
}

sub cond { # eval something
    my ($context, @args) = @_;

    die "cond needs an odd number of arguments.\n" unless @args % 2;

    # else expression
    my $else = pop @args;

    # simple conditionals
    my @cond;
    push @cond, {
        if   => shift(@args),
        then => shift(@args),
    } while @args;

    # conditional eval
    foreach my $cond (@cond) {

        # condition
        my $bool = $cond->{if}->eval($context);
        die "conditions need to return a Boolean.\n"
            unless $bool->isa('PerLisp::Expr::Boolean');

        # true!
        return $cond->{then}->eval($context) if $bool->value;
    }

    # else
    return $else->eval($context);
}

sub equal { # eval both arguments
    my ($context, $a_expr, $b_expr) = @_;

    # eval
    my $a = $a_expr->eval($context);
    my $b = $b_expr->eval($context);

    # false and true expressions
    my $true  = $PerLisp::Expr::Boolean::TRUE;
    my $false = $PerLisp::Expr::Boolean::FALSE;

    # undefined shorthand
    return $false unless defined $a and defined $b;

    # evaluating to the same expression object
    return $true if $a == $b;

    # two booleans
    if (ref($a) =~ /Boolean/ and ref($b) =~ /Boolean/) {
        return $true if $a->value == $b->value;
    }

    # two numbers
    elsif (ref($a) =~ /Number/ and ref($b) =~ /Number/) {
        return $true if $a->value == $b->value;
    }

    # two strings
    elsif (ref($a) =~ /String/ and ref($b) =~ /String/) {
        return $true if $a->value eq $b->value;
    }

    # two symbols
    elsif (ref($a) =~ /Symbol/ and ref($b) =~ /Symbol/) {
        return $true if $a->name eq $b->name;
    }

    # two lists
    elsif (ref($a) =~ /List/ and ref($b) =~ /List/) {

        # different length shorthand
        return $false unless @{$a->exprs} == @{$b->exprs};

        # empty list shorthand
        return $true if @{$a->exprs} == 0 and @{$b->exprs} == 0;

        # check car
        return $false unless equal($context, _q($a->car), _q($b->car))->value;

        # recursive equalness
        return $true if equal($context, _q($a->cdr), _q($b->cdr))->value;
    }

    # else: not equal
    return $false;
}

sub logical_and { # short circuit evaluation
    my ($context, $a_expr, $b_expr) = @_;

    # eval first expression
    my $a = $a_expr->eval($context);

    # booleanness check
    die 'and can\'t be applied on non boolean ' . $a->to_string . "\n"
        unless $a->isa('PerLisp::Expr::Boolean');

    # short circuit: a false
    return $PerLisp::Expr::Boolean::FALSE unless $a->value;

    # eval second expression
    my $b = $b_expr->eval($context);

    # booleanness check
    die 'and can\'t be applied on non boolean ' . $b->to_string . "\n"
        unless $b->isa('PerLisp::Expr::Boolean');

    # a true: return b
    return $b;
}

sub logical_or { # short circuit evaluation
    my ($context, $a_expr, $b_expr) = @_;

    # eval first expression
    my $a = $a_expr->eval($context);

    # booleanness check
    die 'or can\'t be applied on non boolean ' . $a->to_string . "\n"
        unless $a->isa('PerLisp::Expr::Boolean');

    # short circuit: a true
    return $PerLisp::Expr::Boolean::TRUE if $a->value;

    # eval second expression
    my $b = $b_expr->eval($context);

    # booleanness check
    die 'and can\'t be applied on non boolean ' . $b->to_string . "\n"
        unless $b->isa('PerLisp::Expr::Boolean');

    # a false: return b
    return $b;
}

sub logical_not { # eval the argument
    my ($context, $expr) = @_;

    # eval
    my $boolean = $expr->eval($context);

    # booleanness check
    die 'not can\'t be applied on non boolean ' . $boolean->to_string . "\n"
        unless $boolean->isa('PerLisp::Expr::Boolean');

    # not
    return $boolean->value ?
            $PerLisp::Expr::Boolean::FALSE
        :   $PerLisp::Expr::Boolean::TRUE;
}

sub type { # eval the argument
    my ($context, $expr) = @_;

    # eval
    my $val = $expr->eval($context);

    # get class parts
    my $class  = ref $val;
    my @parts  = split /::/ => $class;
    my $type_s = pop @parts;

    # return last part
    return PerLisp::Expr::Symbol->new(name => $type_s);
}

1;
__END__
