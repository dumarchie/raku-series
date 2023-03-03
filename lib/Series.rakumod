class Series {
    has Mu $.value is required;
    has Series $.next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    multi method new(Mu :$value!, Series :$next --> Series:D) {
        self.CREATE!SET-SELF($value<>, $next);
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

=head1 METHODS

=head2 method new

Defined as:

    multi method new(Mu :$value!, Series :$next --> Series:D)

Constructs a C<Series> that links the decontainerized C<$value> to the
C<$next> series.

=end pod
