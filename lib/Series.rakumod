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

    sub infix:<::>(Mu $value, Series $next --> Series:D) is export {
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

    sub infix:<::>(Mu $value, Series $next --> Series:D)

Constructs a C<Series> node that links the decontainerized C<$value> to the
C<$next> series of values.

=head1 METHODS

=head2 method new

Defined as:

    multi method new(Mu :$value!, Series :$next --> Series:D)

Constructs a C<Series> node that links the decontainerized C<$value> to the
C<$next> series of values.

=end pod
