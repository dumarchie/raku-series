use v6.d;

class Series {
    has $.head;
    has $.next;
    method !SET-SELF(Mu \value, \next) {
        $!head := value;
        $!next := next;
        self;
    }

    # define the empty series
    my \Empty = Series.CREATE;
    Empty!SET-SELF(Nil, Empty);

    # only the empty series is false
    multi method Bool(Series:D: --> Bool:D) {
        self !=:= Empty;
    }

    # private node constructor
    sub node(Mu \value, \next) {
        Series.CREATE!SET-SELF(value<>, next);
    }

    # public node constructor
    proto sub infix:<::>(|) is assoc<right> is export {*}
    multi sub infix:<::>(Mu \value, Series:D \next --> Series:D) {
        node(value, next<>);
    }
    multi sub infix:<::>(Mu \value, Nil --> Series:D) {
        node(value, Empty);
    }

    # construct Series from argument list
    method new(**@values is raw --> Series:D) {
        my $self := Empty;
        $self := node($_, $self) for @values.reverse;
        $self;
    }
}

=begin pod

=head1 NAME

Series - Purely functional linked lists

=head1 DESCRIPTION

C<Series> are purely functional data structures implementing linked lists. A
proper series consists of nodes that recursively link a I<value>, the C<.head>
of the series, to the I<next> node. The last proper node links to a sentinel
object representing the empty series. The empty series is the only C<Series>
that evaluates to C<False> in Boolean context.

=head1 OPERATORS

The following operator is exported by default:

=head2 infix ::

    multi sub infix:<::>(Mu \value, Series:D \next --> Series:D)
    multi sub infix:<::>(Mu \value, Nil --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<value> followed by
the C<next> series or the empty series. This operator is right associative, so

    1 :: 2 :: Nil eqv Series.new(1, 2);

Note that C<::> must be surrounded by whitespace to distinguish C<Series>
creation from package names.

=head1 METHODS

=head2 method new

    method new(**@values is raw --> Series:D)

Returns a new C<Series> consisting of the decontainerized C<@values>, or the
empty C<Series> if called without values.

=head2 method Bool

    multi method Bool(Series:D: --> Bool:D)

Returns C<False> if and only if the series is empty.

=head2 method head

    method head(Series:D:)

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

=end pod
