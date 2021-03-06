package PerLisp::Expr::Boolean;
use PerLisp::Mo 'default';

extends 'PerLisp::Expr';

has value => 0;

our $TRUE  = __PACKAGE__->new(value => 1);
our $FALSE = __PACKAGE__->new(value => 0);

sub eval {
    my ($self, $context) = @_;
    return $self;
}

sub to_string {
    my $self = shift;
    return $self->value ? 'true' : 'false';
}

sub to_string_bound {
    my ($self, $context) = @_;
    return $self->to_string;
}

sub to_simple {
    my $self = shift;
    return $self->value ? 'true' : 'false';
}

sub to_simple_bound {
    my ($self, $context) = @_;
    return $self->to_simple;
}

1;
__END__
