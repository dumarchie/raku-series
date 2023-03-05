class Series does Iterable {
    has $.value is required;
    has Series $.next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value<>;
        $!next  := next;
        self;
    }

    # Constructors
    multi method new(Mu :$value!, :$next! --> Series:D) {
        Series.CREATE!SET-SELF($value, $next.self);
    }
    multi method new(Mu :$value! --> Series:D) {
        Series.CREATE!SET-SELF($value, Series);
    }

    proto sub infix:<::>(|) is assoc<right> is export {*}
    multi sub infix:<::>(Mu \value, Nil --> Series:D) {
        Series.CREATE!SET-SELF(value, Series);
    }
    multi sub infix:<::>(Mu \value, Series \next --> Series:D) {
        Series.CREATE!SET-SELF(value, next.self);
    }

    # Iterable implementation
    my class Traversal does Iterator {
        has $.series;
        method pull-one() {
            if my $node = $!series {
                $!series = $node.next;
                $node.value;
            }
            else {
                IterationEnd;
            }
        }
    }
    multi method iterator(Series:D: --> Iterator:D) {
        Traversal.new(series => self);
    }

    # Coercion to Raku list
    multi method list(Series:D: --> List:D) {
        self.Seq.list;
    }
}

=begin pod

=head1 NAME

Series - Purely functional sequences

=head1 DESCRIPTION

    class Series does Iterable {
        has $.value is required;
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

    multi sub infix:<::>(Mu \value, Nil --> Series:D)
    multi sub infix:<::>(Mu \value, Series \next --> Series:D)

Constructs a C<Series> node that links the decontainerized C<value> to the
C<next> series of values or to the C<Series> type object representing the empty
series. This operator is right associative, so if C<::> operations are chained,
all arguments but the last are treated as I<values>.

=head1 METHODS

=head2 method new

    multi method new(Mu :$value!, :$next! --> Series:D)
    multi method new(Mu :$value! --> Series:D)

Constructs a C<Series> node that links the decontainerized C<$value> to the
C<$next> series of values or to the C<Series> type object representing the empty
series.

=head2 method iterator

    multi method iterator(Series:D: --> Iterator:D)

Returns an L<C<Iterator>|https://docs.raku.org/type/Iterator.html> over the
series.

=head2 method list

    multi method list(Series:D: --> List:D)

Returns a lazy L<C<List>|https://docs.raku.org/type/List.html> based on a fresh
C<.iterator>.

=end pod
