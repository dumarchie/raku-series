use v6.d;

# Define fast decont operator
proto sub postfix:«<>»(|) {*}
multi sub postfix:«<>»(Mu \item) { item }

# Define deferred series constructor
my class Series::Deferred is Proxy {}
sub deferred(&init) is raw {
    my $series;
    Series::Deferred.new(
      FETCH => method ()  { $series // ($series := init) },
      STORE => method ($) { die "Cannot assign to an immutable Series" }
    );
}

class Series does Iterable {
    has $!value;
    has $!next;
    method !SET-SELF(Mu \value, \next) {
        $!value := value;
        $!next  := next;
        self;
    }

    # Define the empty series
    my \End = Series.CREATE but False;
    End!SET-SELF(Nil, End);

    # Property accessors may be called on the type object which is a valid
    # representation of the empty series
    proto method value(|) {*}
    multi method value(Series:U: --> Nil) { }
    multi method value(Series:D:) { $!value }

    proto method next(|) {*}
    multi method next(Series:U: --> Series:D) { End }
    multi method next(Series:D: --> Series:D) {
        $!next.VAR =:= $!next ?? $!next !! ($!next := $!next());
    }

    # The identity function is useful when another thread has concurrently
    # replaced a Callable with the Series it returned
    method CALL-ME() { self }

    # Constructors
    proto sub infix:<::>(|) is assoc<right> is equiv(&infix:<,>) is export {*}
    multi sub infix:<::>(Mu \item, Series \next --> Series:D) {
        next.insert(item);
    }

    multi method new( --> Series:D) { End }
    multi method new(Mu \item --> Series:D) {
        End.insert(item);
    }
    multi method new(Slip \items --> Series:D) {
        End!insert-list(items);
    }
    multi method new(**@items is raw --> Series:D) {
        End!insert-list(@items);
    }
    method !insert-list(@items) {
        my $self := self;
        $self := $self.insert($_) for @items.reverse;
        $self;
    }

    proto method insert(|) {*}
    multi method insert(Series:U: Mu \item --> Series:D) {
        End.insert(item);
    }
    multi method insert(Series:D: Mu \item --> Series:D) {
        ::?CLASS.CREATE!SET-SELF(item<>, self);
    }

    # Concatenation
    method prepend(Iterable \items) is raw {
        my \iter = items.iterator;
        my \lock = Lock.new;
        my &copy = {
            my $state = {
                lock.protect({
                    if $state ~~ Callable {
                        my \item = iter.pull-one;
                        $state := (item =:= IterationEnd)
                          ?? self // End
                          !! ::?CLASS.CREATE!SET-SELF(item<>, copy);
                    }
                    $state;
                });
            };
        };
        deferred copy;
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

    multi sub infix:<::>(Mu \item, Series \next --> Series:D)

Constructs a new C<Series> consisting of the decontainerized C<item> followed
by the values of the C<next> series. This operator is right associative, so
the following statement is true:

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

    multi method insert(Series:U: Mu \item --> Series:D)
    multi method insert(Series:D: Mu \item --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<item> followed by
the values of the invocant.

=head2 method prepend

    method prepend(Iterable \items) is raw

Returns a deferred C<Series> of lazily evaluated, decontainerized C<items>
followed by the values of the invocant.

=head2 method iterator

    method iterator( --> Iterator:D)

Returns an C<Iterator> over the values in the series.

=head2 method elems

    method elems( --> Int:D)

Returns the number of values in the series.

=head2 method head

    multi method head()

Returns the value at the head of the series, or C<Nil> if the series is empty.

=head2 method next

    multi method next(Series:U: --> Series:D)
    multi method next(Series:D: --> Series:D)

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
