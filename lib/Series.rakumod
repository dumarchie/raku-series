my $Empty; # will be bound to the Series::End singleton

class Series does Iterable {
    has Mu $.value is required;
    has Series $.next;
    method !SET-SELF(Mu \value, Series \next) {
        $!value := value<>;
        $!next  := next;
        self;
    }

    # Constructors
    proto method new(|) {*}
    multi method new(--> Series:D) { $Empty }
    multi method new(Mu :$value!, :$next --> Series:D) {
        Series.CREATE!SET-SELF($value, $next.self // $Empty);
    }

    proto sub infix:<::>(|) is assoc<right> is export {*}
    multi sub infix:<::>(Mu \value, Nil --> Series:D) {
        Series.CREATE!SET-SELF(value, $Empty);
    }
    multi sub infix:<::>(Mu \value, Series \next --> Series:D) {
        Series.CREATE!SET-SELF(value, next.self // $Empty);
    }

    # Destructuring
    multi method head(Series:D:) { $!value }

    multi method skip(Series:D: --> Series:D) { $!next  }
    multi method skip(Int() $n = 1 --> Series:D) {
        my $node := self // $Empty;
        my int $i = $n;
        $node := $node.next while $node && $i-- > 0;
        $node;
    }

    # Iterable implementation
    my class Traversal does Iterator {
        has $.series;
        method pull-one() {
            if my $node = $!series {
                $!series := $node.next;
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

$Empty := class Series::End is Series {
    multi method Bool(::?CLASS:D: --> False) { }
    multi method head( --> Nil) { }
    multi method skip( --> Series:D) { $Empty }
    multi method raku(::?CLASS:D: --> 'Series.new') { }
}.CREATE;

=begin pod

=head1 NAME

Series - Purely functional sequences

=head1 DESCRIPTION

    class Series does Iterable { }

A C<Series> is a purely functional B<linked list>, a recursive data structure
consisting of nodes that link a I<value> to the I<next> node. The first node
represents the whole series, as all values can be accessed by repeatedly
following the link to the next node. The final node links to a singleton
instance of the class representing the empty C<Series>:

    class Series::End is Series {
        multi method Bool(::?CLASS:D: --> False)
    }

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

    multi method new(--> Series:D)
    multi method new(Mu :$value!, :$next --> Series:D)

Returns the empty series if called without value. Otherwise constructs a
C<Series> node that links the decontainerized C<$value> to the C<$next> series
of values or to the empty series.

=head2 method head

    multi method head(Series:D:)

Returns the B<first> value of the series, or C<Nil> if the series is empty.

=head2 method skip

    multi method skip(Series:D: --> Series:D)
    multi method skip(Int() $n = 1 --> Series:D)

Returns the C<Series> that remains after discarding the first value or C<$n>
values. Negative values of C<$n> count as 0.

=head2 method iterator

    multi method iterator(Series:D: --> Iterator:D)

Returns an L<C<Iterator>|https://docs.raku.org/type/Iterator.html> over the
series.

=head2 method list

    multi method list(Series:D: --> List:D)

Returns a lazy L<C<List>|https://docs.raku.org/type/List.html> based on a fresh
C<.iterator>.

=end pod
