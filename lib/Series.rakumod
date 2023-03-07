my $Empty; # will be bound to the Series::End singleton
my &cons;  # protected Series::Node constructor

class Series does Iterable {
    # Constructors
    proto method new(|) {*}
    multi method new(--> Series:D) { $Empty }
    multi method new(Mu :$value!, :$next --> Series:D) {
        cons($value, $next.self // $Empty);
    }
    multi method new(**@values is raw --> Series:D) {
        $Empty!insert-list(@values);
    }

    method insert(**@values is raw --> Series:D) {
        my $series := self // $Empty;
        $series!insert-list(@values);
    }
    method !insert-list(@values) {
        my $series := self;
        $series := cons($_, $series) for @values.reverse;
        $series;
    }

    proto sub infix:<::>(|) is assoc<right> is export {*}
    multi sub infix:<::>(Mu \value, Nil --> Series:D) {
        cons(value, $Empty);
    }
    multi sub infix:<::>(Mu \value, Series \next --> Series:D) {
        cons(value, next.self // $Empty);
    }

    # Destructuring
    multi method head( --> Nil) { }

    multi method skip( --> Series:D) { $Empty }
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

    # Coercion
    multi method list(Series:D: --> List:D) {
        self.Seq.list;
    }

    multi method raku(Series:D: --> Str:D) {
        "Series.new{ self.list.raku }";
    }
}

$Empty := class Series::End is Series {
    multi method Bool(::?CLASS:D: --> False) { }
}.CREATE;

class Series::Node is Series {
    has Mu $.value is required;
    has Series $.next;
    method !SET-SELF(Mu \value, Series \next) {
        $!value := value<>;
        $!next  := next;
        self;
    }

    # Protected constructor
    &cons = sub (Mu \value, Series \next) {
        ::?CLASS.CREATE!SET-SELF(value, next);
    }

    # Destructuring
    multi method head(::?CLASS:D:) { $!value }
    multi method skip(::?CLASS:D: --> Series:D) { $!next  }
}

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
C<next> series of values or, if the right operand is not defined, to the empty
series. This operator is right associative, so if C<::> operations are chained,
all arguments but the last are treated as I<values>.

=head1 METHODS

=head2 method new

    multi method new(--> Series:D)
    multi method new(Mu :$value!, :$next --> Series:D)
    multi method new(**@values is raw --> Series:D)

Returns the empty series if called without arguments. Otherwise constructs a
C<Series> node that links the decontainerized C<$value> or C<@values> to the
empty series.

=head2 method insert

    method insert(**@values is raw --> Series:D)

Returns a I<new> series that links the decontainerized C<@values> to the
invocant series, or to the empty series if the invocant is a type object.

=head2 method head

Defined as:

    multi method head()

Returns the B<first> value of the series, or C<Nil> if called on an empty or
undefined series.

=head2 method skip

Defined as:

    multi method skip( --> Series:D)
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

=head2 method raku

    multi method raku(Series:D: --> Str:D)

Returns a string that L<evaluates|https://docs.raku.org/routine/EVAL.html> to an
equivalent series.

=end pod
