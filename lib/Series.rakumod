use v6.d;

class Series does Iterable {
    has $.value;
    has $.next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # construct the empty series
    my \Empty = Series.CREATE;
    Empty!SET-SELF(Nil, Empty);

    # cons operator
    proto sub infix:<::>(|) is assoc<right> is equiv(&infix:<,>) is export {*}
    multi sub infix:<::>(Mu $var is rw, Series:D \next --> Series:D) {
        Series.CREATE!SET-SELF($var<>, next);
    }
    multi sub infix:<::>(Mu \value, Series:D \next --> Series:D) {
        Series.CREATE!SET-SELF(value, next);
    }
    multi sub infix:<::>(Mu $var is rw, Series:U --> Series:D) {
        Series.CREATE!SET-SELF($var<>, Empty);
    }
    multi sub infix:<::>(Mu \value, Series:U --> Series:D) {
        Series.CREATE!SET-SELF(value, Empty);
    }

    # public low-level node constructor
    method insert(Mu \value --> Series:D) {
        my \head = value.VAR =:= value ?? value !! value<>;
        self.CREATE!SET-SELF(head, self // self.new);
    }

    # default constructor
    multi method new( --> Series:D) { Empty }
    multi method new(**@values is raw --> Series:D) {
        my $self := Empty;
        $self := $self.insert($_) for @values.reverse;
        $self;
    }

    # provide our own method bless, rather than a public submethod BUILD, so
    # we can constrain the "next" attribute without providing an update method
    method bless(Mu :$value, Series :$next --> Series:D) {
        $next.insert($value);
    }

    # only the empty series is false
    multi method Bool(Series:D: --> Bool:D) {
        self !=:= Empty;
    }

    # return the raw $!value so we can check we bind to a bare value
    multi method head(Series:D:) is raw { $!value }

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
        $values ?? "($values :: Series)" !! 'Series.new';
    }
}

=begin pod

=head1 NAME

Series - Purely functional linked lists

=head1 DESCRIPTION

    class Series does Iterable {}

C<Series> are strongly immutable linked lists. A proper series consists of nodes
that recursively link a I<value>, the C<.head> of the series, to the I<next>
node. The last true node of a series links to a sentinel node representing the
empty series. This sentinel node has no value, links to itself and is the only
node that evaluates to C<False> in Boolean context.

C<Series> are L<C<Iterable>|https://docs.raku.org/type/Iterable>, but they are
not C<Positional> so they're not lists in the Raku sense of the word.

=head1 OPERATORS

The following operator is exported by default:

=head2 infix ::

Defined as:

    sub infix:<::>(Mu \value, Series \next --> Series:D)

Constructs and returns a new C<Series> consisting of the decontainerized
C<value> followed by the values of the C<next> series. This operator is right
associative, so the following statement is true:

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

    multi method new( --> Series:D)
    multi method new(**@values is raw --> Series:D)

Returns the empty series if no values are provided. Otherwise returns a new
C<Series> consisting of the decontainerized C<@values>.

=head2 method bless

Defined as

    method bless(Mu :$value, Series :$next --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<$value> followed by
the values of the C<$next> series. It's usually more straightforward to call
L<C<$next.insert($value)>|#method_insert>.

=head2 method insert

    method insert(Mu \value --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<value> followed by
the values of the invocant.

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
