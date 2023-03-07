use Test;

use lib 'lib';
use Series;

subtest '.new', {
    subtest 'call without arguments', {
        my $series = Series.new;
        isa-ok $series, Series:D, 'my $series = Series.new';
        cmp-ok $series.Bool, '=:=', False,        '$series.Bool';
        cmp-ok $series.head, '=:=', Nil,          '$series.head';
        cmp-ok $series.skip, '=:=', $series.self, '$series.head';
        is $series.raku, 'Series.new()',          '$series.raku';
    };

    # assert that the constructor accepts a named "value" of type Mu
    subtest 'calls with named arguments', {
        my Mu $value;
        my $node = Series.new(:$value);
        isa-ok $node, Series:D, 'my $node = Series.new(:$value)';

        # assert that $!value is not bound to the provided container
        $value .= new;
        cmp-ok $node.head, '=:=', Mu,         '$node.head';
        cmp-ok $node.skip, '=:=', Series.new, '$node.skip';

        # assert that named argument "next" initializes $!next
        my $next = $node;
        my $node2 = $node.new(:$value, :$next);
        isa-ok $node, Series:D, 'my $node2 = $node.new(:$value, :$next)';

        # assert that $!next is not bound to the provided container
        $next = Any.new;
        cmp-ok $node2.skip, '=:=', $node.self, '$node2.skip';

        # assert that named arguments are ignored if "next" is not a Series
        throws-like { $node.new(:$value, :$next) }, X::TypeCheck::Binding,
          'The :next argument must be of type Series';
    };

    subtest 'calls with positional arguments', {
        cmp-ok Series.new(Empty), '=:=', Series.new, 'Series.new(Empty)';

        my Mu $value;
        my $series = Series.new($value, 42);
        isa-ok $series, Series:D, 'my $series = Series.new($value, 42)';

        # assert that $!value is not bound to the provided container
        $value .= new;
        is $series.raku, 'Series.new(Mu, 42)', '$series.raku';
    };
};

subtest 'infix ::', {
    # assert that infix :: accepts a Mu left operand
    my Mu $value;

    my $series;
    subtest '$value :: Nil', {
        $series = $value :: Nil;
        isa-ok $series, Series:D, '$series = $value :: Nil';

        # assert that $!value is not bound to the provided container
        $value .= new;
        cmp-ok $series.head, '=:=', Mu,         '$series.head';
        cmp-ok $series.skip, '=:=', Series.new, '$series.skip';
    };

    # assert that a concrete right operand initializes $!next
    my $right = $series;
    subtest '$value :: $series', {
        my $series2 = $value :: $right;
        isa-ok $series2, Series:D, 'my $series2 = $value :: $series';

        # assert that $!next is not bound to the provided container
        $right = Any.new;
        cmp-ok $series2.skip, '=:=', $series.self, '$series2.skip';
    };

    subtest 'infix:<::> is right associative', {
        my $series3 = $value :: $series :: Series;
        isa-ok $series3, Series:D, 'my $series3 = $value :: $series :: Series';
        is $series3.raku, "Series.new({ $value.raku }, { $series.raku })",
          '$series3.raku';
    };

    throws-like { $value :: $right }, X::Multi::NoMatch,
      'the right operand must be Nil or of type Series';
};

subtest '.skip($n)', {
    cmp-ok Series.skip, '=:=', Series.new, 'Series.skip';

    my $series = Series.new(1, 2);
    cmp-ok $series.skip(-1), '=:=', $series.self, '$series.skip(-1)';
    cmp-ok $series.skip(1),  '=:=', $series.skip, '$series.skip(1)';
    cmp-ok $series.skip(3),  '=:=', Series.new,   '$series.skip(3)';
};

subtest '.iterator', {
    my $series = Series.new(1, 2);
    my $iterator = $series.iterator;
    does-ok $iterator, Iterator:D, 'my $iterator = $series.iterator';
    cmp-ok $iterator.pull-one, '=:=', 1, '$iterator.pull-one';
    cmp-ok $iterator.pull-one, '=:=', 2, '$iterator.pull-one';
    cmp-ok $iterator.pull-one, '=:=', IterationEnd, '$iterator.pull-one';
};

subtest '.list', {
    my $series = Series.new(1, 2);
    my $list = $series.list;
    does-ok $list, List:D, 'my $list = $series.list';
    is-deeply $list, (1, 2), '$list contents';
};

done-testing;
