class Series {
    has Mu $.value is required;
    has Series $.next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # Constructors
    multi method new(Mu :$value!, Series :$next --> Series:D) {
        self.CREATE!SET-SELF($value<>, $next);
    }

    proto sub infix:<::>(|) is assoc<right> is export {*}
    multi sub infix:<::>(Mu $value, Nil --> Series:D) {
        Series.CREATE!SET-SELF($value<>, Series);
    }
    multi sub infix:<::>(Mu $value, Series $next --> Series:D) {
        Series.CREATE!SET-SELF($value<>, $next);
    }
}

=begin pod

=head1 NAME

Series - Purely functional sequences

=head1 DESCRIPTION

    class Series {
        has Mu $.value is required;
        has Series $.next;
    }

A C<Series> is a purely functional B<linked list>, a recursive data structure
consisting of nodes that link a I<value> to the I<next> node. The first node
represents the whole series, as all values can be accessed by repeatedly
following the link to the next node. The final node links to the C<Series> type
object that represents the empty series.

=head1 OPERATORS

C<Series> exports the following operator that constructs a linked list node:

=head2 infix ::

    multi sub infix:<::>(Mu $value, Nil --> Series:D)
    multi sub infix:<::>(Mu $value, Series $next --> Series:D)

Constructs a C<Series> node that links the decontainerized C<$value> to the
C<$next> series of values or to the C<Series> type object representing the empty
series. This operator is right associative, so if C<::> operations are chained,
all arguments but the last are treated as I<values>.

=head1 METHODS

=head2 method new

Defined as:

    multi method new(Mu :$value!, Series :$next --> Series:D)

Constructs a C<Series> node that links the decontainerized C<$value> to the
C<$next> series of values.

=end pod
