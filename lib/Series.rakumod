class Series {
    has Mu $.value is required;
    has Series $.next;
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
that consists of nodes which link a I<value> to the I<next> node. The first node
represents the whole series, as all values can be accessed by repeatedly
following the link to the next node.

=end pod
