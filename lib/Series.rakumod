use v6.d;

# Define fast decont operator
proto sub postfix:«<>»(|) {*}
multi sub postfix:«<>»(Mu \value) { value }

# Define deferred series constructor
my class Series::Deferred is Proxy {}
sub deferred(&init) is raw {
    my $series;
    Series::Deferred.new(
      FETCH => method ()  { $series // ($series := init) },
      STORE => method ($) { die "Cannot assign to an immutable Series" }
    );
}

# To be defined when class Series has been defined:
my &cons; # protected Series::Node constructor

my $Empty := class Series does Iterable {
    # In case another thread has concurrently replaced a Callable with a Series
    method CALL-ME() { self }

    # Constructors
    proto method new(|) {*}
    multi method new( --> Series:D) { $Empty }
    multi method new(Mu \value --> Series:D) {
        $Empty.insert(value);
    }
    multi method new(Slip \values --> Series:D) {
        $Empty!insert-list(values);
    }
    multi method new(**@values is raw --> Series:D) {
        $Empty!insert-list(@values);
    }
    method !insert-list(@values) {
        my $self := self;
        $self := cons($_<>, $self) for @values.reverse;
        $self;
    }

    method insert(Mu \value --> Series:D) {
        cons(value<>, $Empty);
    }

    # Concatenation
    method prepend(Mu \values) is raw {
        my \iter = values.iterator;
        my \lock = Lock.new;
        my &copy = {
            my $state = {
                lock.protect({
                    if $state ~~ Callable {
                        my \value = iter.pull-one;
                        $state := (value =:= IterationEnd)
                          ?? self // $Empty
                          !! cons(value<>, copy);
                    }
                    $state;
                });
            };
        };
        deferred copy;
    }

    # This base class represents the empty series. Both the type object and
    # object instances are valid representations of the empty series. Hence
    # there's NO concreteness check on the invocant in these accessors:
    method Bool( --> Bool:D) { False }

    method elems( --> Int:D) { 0 }

    multi method head() { Nil }

    method iterator( --> Iterator:D) { Empty.iterator }

    method list( --> List:D) { self.Seq.list }

    method next( --> Series:D) { $Empty }

    multi method skip() is raw { $Empty }
    multi method skip(Int() \n) is raw { $Empty }

    # Stringification does depend on concreteness
    multi method gist(::?CLASS:D: --> Str:D) { self.Seq.gist }

    multi method raku(::?CLASS:D: --> Str:D) { 'Series.new' }
}.CREATE;

# To turn any Iterable into a series
proto sub series(|) {*}
multi sub series(Series:D \values) { values }
multi sub series(Series:U) { $Empty }
multi sub series(Mu \values) is raw {
    $Empty.prepend(values);
}

my class Series::Node is Series {
    has $.value;
    has $!next;
    method !SET-SELF(Mu \value, Mu \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # This protected cons function expects the caller to
    # sanitize the next argument
    &cons = -> Mu \value, Mu \next {
        ::?CLASS.CREATE!SET-SELF(value, next);
    }

    # This public cons operator constrains the next argument
    sub infix:<::>(Mu \value, Mu \next --> Series:D)
      is assoc<right> is equiv(&infix:<,>) is export
    {
        ::?CLASS.CREATE!SET-SELF(value<>, next.VAR.WHAT =:= Series::Deferred
          ?? next
          !! series(next)
        );
    }

    # Object-oriented constructor
    method insert(::?CLASS:D: Mu \value --> Series:D) {
        ::?CLASS.CREATE!SET-SELF(value<>, self);
    }

    # Instances of this subclass represent a proper series. Note that the
    # type object is NOT a valid representation of the empty series. Hence
    # there IS a concreteness check on the invocant in these accessors:
    method Bool(::?CLASS:D: --> True) {}

    method elems(::?CLASS:D: --> Int:D) {
        my $node := self;
        my int $elems = 1;
        $elems++ while $node := $node.next;
        $elems;
    }

    multi method head(::?CLASS:D:) { $!value }

    method iterator(::?CLASS:D: --> Iterator:D) {
        class :: does Iterator {
            has $.node;
            method pull-one() {
                ($!node := $!node.next) ?? $!node.value !! IterationEnd;
            }
        }.new(node => cons(Nil, self));
    }

    method next(::?CLASS:D: --> Series:D) {
        $!next.VAR =:= $!next ?? $!next !! ($!next := $!next());
    }

    multi method skip(::?CLASS:D:) is raw {
        $!next.VAR =:= $!next ?? $!next !! deferred { $!next := $!next() };
    }
    multi method skip(::?CLASS:D: Int() \n) is raw {
        my $series := self;
        my int $n = n;
        while --$n > 0 {
            $series := $series.next or $n = 0;
        }
        $n == 0 ?? $series.skip !! $series;
    }

    # Stringification
    multi method raku(::?CLASS:D: --> Str:D) {
        "({join ' :: ', self.map(*.raku)} :: Empty)";
    }
}

=begin pod

=head1 NAME

Series - Purely functional, potentially lazy linked lists

=head1 DESCRIPTION

    class Series does Iterable {}

C<Series> are strongly immutable linked lists. A series consists of nodes that
recursively link a I<value>, the C<.head> of the series, to the I<next> node.
The last node of a series links to the empty series, the only C<Series> object
instance that evaluates to C<False> in Boolean context.

While C<Series> are L<C<Iterable>|https://docs.raku.org/type/Iterable>, they're
not C<Positional>, so they're not "lists" in the Raku sense of the word. But
like the elements of Raku lists, the nodes of a series may be lazily evaluated.
As the first node represents the whole series, a series with a lazy head is
represented by a C<Proxy>. A method that returns such a I<deferred> series has
the C<is raw> trait instead of an explicit return type. Clients that wish to
delay evaluation of the head should bind to the result, rather than assign it.

=head1 OPERATORS

The following operator is exported by default:

=head2 infix ::

    sub infix:<::>(Mu \value, Mu \next --> Series:D)

Constructs a C<Series> that consists of the decontainerized C<value> followed by
the values produced by the C<next.iterator>. This operator is right associative,
so the following statement is true:

    (1 :: 2 :: Empty) eqv Series.new(1, 2);

Note that the C<::> operator has the same
L<precedence|https://docs.raku.org/language/operators#Operator_precedence> as
the C«,» operator, so the following statements are all equivalent:

    1 :: 2 :: Empty eqv Series.new(1, 2);
    1 :: 2 :: (Empty eqv Series.new(1, 2));
    1 :: 2 :: False;

Also note that C<::> must be surrounded by whitespace to distinguish a C<Series>
construct from a package name.

=head1 METHODS

=head2 method Bool

    method Bool( --> Bool:D)

Returns C<False> if the series is empty, C<True> if it consists of one or more
values.

=head2 method new

Defined as

    method new(**@values --> Series:D)

Returns the empty series if no values are provided. Otherwise returns a new
C<Series> consisting of the decontainerized C<@values>.

=head2 method insert

    method insert(Mu \value --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<value> followed by
the values of the invocant.

=head2 method prepend

    method prepend(Mu \values) is raw

Constructs a deferred C<Series> that consists of the values produced by the
C<values.iterator> followed by the values of the invocant.

=head2 method elems

    method elems( --> Int:D)

Returns the number of values in the series.

=head2 method head

    multi method head()

Returns the value at the head of the series, or C<Nil> if the series is empty.

=head2 method iterator

    method iterator( --> Iterator:D)

Returns an C<Iterator> over the values in the series.

=head2 method list

    method list( --> List:D)

Coerces the series to a lazy C<List> of values.

=head2 method next

    method next( --> Series:D)

Returns the C<Series> following the L<C<.head>|#method_head> of the invocant.
Note that C<.next> returns the empty series if called on a series without
values, so always check you're dealing with a proper C<Series> if you're
calling C<.next> in a loop. For example:

    my $series = Series.new(1, 2, 3);
    while $series {
        print $series.head;
        $series .= next;
    }
    print "\n";

    # OUTPUT: «123␤»

=head2 method skip

    multi method skip() is raw
    multi method skip(Int() \n) is raw

Returns the potentially deferred series of values that remains after discarding
the first value or first C<n> values of the invocant. Negative values of C<n>
count as 0, and

    $series.skip(0) === $series.self;

=head2 method gist

    multi method gist(Series:D: --> Str:D)

Returns a string containing the parenthesized "gist" of the series.

=head2 method raku

    multi method raku(Series:D: --> Str:D)

Returns a string that can be used to reconstruct the series via `EVAL`. Note
that this works only if all values provide a `.raku` that allows them to be
reconstructed this way.

=end pod
