package PerLisp::Expr;
use PerLisp::Mo;

sub eval {
    my ($self, $context) = @_;
    die 'override!';
}

sub to_string { die 'override!' }

sub to_string_bound {
    my ($self, $context) = @_;
    die 'override!';
}

sub to_simple { die 'override!' }

sub to_simple_bound {
    my ($self, $context) = @_;
    die 'override!';
}

1;
__END__
