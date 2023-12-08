use v6.d;

# To be defined in due time:
my $Empty; # the Series::End singleton
my &cons;  # protected Series::Node constructor

role Series does Iterable {
    # Properties of the empty series
    method value() { Nil }
    method next( --> Series:D) { $Empty }

    # Low-level constructors
    proto method insert(|) {*}
    multi method insert(Series:U: Mu \item) {
        $Empty.insert(item);
    }
    multi method insert(Series:D: Mu \item) {
        my \value = item.VAR =:= item ?? item !! item<>;
        cons(value, self);
    }

    proto sub infix:<::>(|) is assoc<right> is equiv(&infix:<,>) is export {*}
    multi sub infix:<::>(Mu \item, Series \next --> Series:D) {
        next.insert(item);
    }

    # Default constructor
    multi method new( --> Series:D) { $Empty }
    multi method new(Mu \item --> Series:D) {
        $Empty.insert(item);
    }
    multi method new(Slip \items --> Series:D) {
        $Empty!insert-list(items);
    }
    multi method new(**@items is raw --> Series:D) {
        $Empty!insert-list(@items);
    }
    method !insert-list(@items) {
        my $self := self;
        $self := $self.insert($_) for @items.reverse;
        $self;
    }

    # The iterator makes series Iterable
    method iterator( --> Iterator:D) {
        class :: does Iterator {
            has $.series;
            method pull-one() {
                my \node = $!series
                  or return IterationEnd;

                $!series := node.next;
                node.value;
            }
        }.new(series => self);
    }

    # Specialized Iterable methods
    # Note that the type object is a valid representation of the empty series.
    method elems( --> Int:D) {
        my $node := self or return 0;
        my int $elems = 1;
        $elems++ while $node := $node.next;
        $elems;
    }

    multi method head() { self.value }

    method list( --> List:D) { self.Seq.list }

    # Stringification
    multi method gist(Series:D: --> Str:D) { self.Seq.gist }

    multi method raku(Series:D: --> Str:D) {
        self ?? "({join ' :: ', self.map: *.raku} :: Series)" !! 'Series.new';
    }
}

# The empty series is the only false Series instance
$Empty := class Series::End does Series {
    multi method Bool(Series:D: --> False) {}
}.CREATE;

class Series::Node does Series {
    has $!value;
    has $!next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    &cons = sub (Mu \value, \next) {
        ::?CLASS.CREATE!SET-SELF(value, next);
    }

    # Node properties
    method value(Series:D:) { $!value }
    method next(Series:D: --> Series:D) { $!next }
}

=begin pod

=head1 NAME

Series - Purely functional linked lists

=head1 DESCRIPTION

    role Series does Iterable {}

C<Series> are strongly immutable linked lists. A proper series consists of
nodes that recursively link a I<value>, the C<.head> of the series, to the
I<next> node. The last node of a series links to the empty series, which has no
value, links to itself, and evaluates to C<False> in Boolean context.

C<Series> are L<C<Iterable>|https://docs.raku.org/type/Iterable>, but they are
not C<Positional> so they're not lists in the Raku sense of the word.

=head1 OPERATORS

The following operator is exported by default:

=head2 infix ::

Defined as:

    sub infix:<::>(Mu \item, Series \next --> Series:D)

Constructs and returns a new C<Series> consisting of the decontainerized C<item>
followed by the values of the C<next> series. This operator is right associative
so the following statement is true:

    (1 :: 2 :: Series) eqv Series.new(1, 2);

Note that the C<::> operator has the same
L<precedence|https://docs.raku.org/language/operators#Operator_precedence> as
the C«,» operator, so the following statements are all equivalent and I<invalid>
because C<False> is not an acceptable right operand:

    1 :: 2 :: Series eqv Series.new(1, 2);
    1 :: 2 :: (Series eqv Series.new(1, 2));
    1 :: 2 :: False;

Also note that C<::> must be surrounded by whitespace to distinguish a C<Series>
from a package name.

=head1 METHODS

=head2 method new

Defined as

    multi method new(**@items --> Series:D)

Returns the empty series if no items are provided. Otherwise returns a new
C<Series> consisting of the decontainerized C<@items>.

=head2 method insert

    multi method insert(Series:U: Mu \item)
    multi method insert(Series:D: Mu \item)

Returns a new C<Series> consisting of the decontainerized C<item> followed by
the values of the invocant.

=head2 method next

    method next( --> Series:D:)

Returns the C<Series> following the L<C<.head>|#method_head> of the invocant.
Note that C<.next> returns the empty series if called on an empty series, so
always check you're dealing with a proper C<Series> if you're calling C<.next>
in a loop. For example:

    my $series = Series.new(1, 2, 3);
    while $series {
        print $series.head;
        $series .= next;
    }
    print "\n";

    # OUTPUT: «123␤»

=head2 method iterator

    method iterator( --> Iterator:D)

Returns an C<Iterator> over the values in the series.

=head2 method elems

    method elems( --> Int:D)

Returns the number of values in the series.

=head2 method head

    multi method head()

Returns the value at the head of the series, or C<Nil> if the series is empty.

=head2 method list

    method list( --> List:D)

Coerces the series to C<List>.

=head2 method gist

    multi method gist(Series:D: --> Str:D)

Returns a string containing the parenthesized "gist" of the series.

=head2 method raku

    multi method raku(Series:D: --> Str:D)

Returns a string that can be used to reconstruct the series via `EVAL`. Note
that this works only if all values provide a `.raku` that allows them to be
reconstructed this way.

=end pod
