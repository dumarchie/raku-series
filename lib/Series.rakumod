use v6.d;

class Series does Iterable {
    has $.value;
    has $.next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # define the empty series
    my \Empty = Series.CREATE;
    Empty!SET-SELF(Nil, Empty);

    # only the empty series is false
    multi method Bool(Series:D: --> Bool:D) {
        self !=:= Empty;
    }

    multi method head(Series:D:) { $!value }

    # basic node constructor
    proto method insert(|) {*}
    multi method insert(Mu $value is rw) {
        Series.CREATE!SET-SELF($value<>, self);
    }
    multi method insert(Mu \value) {
        Series.CREATE!SET-SELF(value, self);
    }

    # cons operator
    proto sub infix:<::>(|) is assoc<right> is equiv(&infix:<,>) is export {*}
    multi sub infix:<::>(Mu \value, Series:D \next --> Series:D) {
        next.insert(value);
    }
    multi sub infix:<::>(Mu \value, Nil --> Series:D) {
        Empty.insert(value);
    }

    # construct Series from argument list
    method new(**@values is raw --> Series:D) {
        my $self := Empty;
        $self := $self.insert($_) for @values.reverse;
        $self;
    }

    # provide iterator
    method iterator(Series:D: --> Iterator:D) {
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

    multi method list(Series:D: --> List:D) { self.Seq.list }

    multi method gist(Series:D: --> Str:D)  { self.Seq.gist }

    multi method raku(Series:D: --> Str:D)  {
        my $values = join ' :: ', self.map: *.raku;
        $values ?? "($values :: Nil)" !! 'Series.new';
    }
}

=begin pod

=head1 NAME

Series - Purely functional linked lists

=head1 DESCRIPTION

    class Series does Iterable {}

C<Series> are immutable linked lists. A proper series consists of nodes that
recursively link a I<value>, the C<.head> of the series, to the I<next> node.
The last proper node links to a sentinel object representing the empty series,
which is the only C<Series> that evaluates to C<False> in Boolean context.

C<Series> are L<C<Iterable>|https://docs.raku.org/type/Iterable>, but they are
not C<Positional> so they're not lists in the Raku sense of the word.

=head1 OPERATORS

The following operator is exported by default:

=head2 infix ::

    multi sub infix:<::>(Mu \value, Series:D \next --> Series:D)
    multi sub infix:<::>(Mu \value, Nil --> Series:D)

L<Constructs|#method_insert> and returns a new C<Series> consisting of the
decontainerized C<value> followed by the C<next> series or the empty series.
This operator is right associative, so the following statement is true:

    (1 :: 2 :: Nil) eqv Series.new(1, 2);

Note that the C<::> operator has the same
L<precedence|https://docs.raku.org/language/operators#Operator_precedence> as
the C«,» operator, so the following statements are all equivalent and I<invalid>
because C<False> is not an acceptable right operand:

    1 :: 2 :: Nil eqv Series.new(1, 2);
    1 :: 2 :: (Nil eqv Series.new(1, 2));
    1 :: 2 :: False;

Also note that C<::> must be surrounded by whitespace to distinguish a C<Series>
from a package name.

=head1 METHODS

=head2 method new

    method new(**@values is raw --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<@values>, or the
empty C<Series> if called without values.

=head2 method insert

Defined as

    method insert(\value --> Series:D)

This is the basic C<Series> node constructor. It returns a new node consisting
of the decontainerized C<value> and the invocant.

=head2 method Bool

    multi method Bool(Series:D: --> Bool:D)

Returns C<False> if and only if the series is empty.

=head2 method head

    multi method head(Series:D:)

Returns the value at the head of the series, or C<Nil> if the series is empty.

=head2 method next

    method next(Series:D:)

Returns the C<Series> following the L<C<.head>|#method_head> of the invocant.
Note that this is the invocant self if empty, so you better check you're dealing
with a proper C<Series> if you're calling C<.next> in a loop. For example:

    my $series = Series.new(1, 2, 3);
    while $series {
        print $series.head;
        $series .= next;
    }
    print "\n";

    # OUTPUT: «123␤»

=head2 method iterator

    method iterator(Series:D: --> Iterator:D)

Returns an C<Iterator> over the values in the series.

=head2 method list

    multi method list(Series:D: --> List:D)

Coerces the series to C<List>.

=head2 method gist

    multi method gist(Series:D: --> Str:D)

Returns a string containing the parenthesized "gist" of the series.

=head2 method raku

    multi method raku(Series:D: --> Str:D)

Returns a string that reconstructs the series when passed to `EVAL`.

=end pod
