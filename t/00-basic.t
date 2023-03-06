use Test;

use lib 'lib';
use Series;

subtest 'named argument constructor', {
    # assert that the constructor requires a value
    my Series $node;
    diag 'my Series $node';
    throws-like { $node .= new }, Exception, message => /«value»/,
      "Named parameter 'value' is required";

    # assert that the constructor accepts a Mu "value"
    my Mu $value;
    diag 'my Mu $value';
    subtest 'Series.new(:$value)', {
        $node .= new(:$value);
        isa-ok $node, Series:D, '$node .= new(:$value)';

        # assert that $!value is not bound to the provided container
        $value .= new;
        cmp-ok $node.value, '=:=', Mu,     '$node.value';
        cmp-ok $node.next,  '=:=', Series, '$node.next';
    };

    # assert that named argument "next" initializes $!next
    my $next = $node;
    diag 'my $next = $node';
    subtest 'Series.new(:$value, :$next)', {
        my $node2 = $node.new(:$value, :$next);
        isa-ok $node, Series:D, 'my $node2 = $node.new(:$value, :$next)';

        # assert that $!next is not bound to the provided container
        $next = Nil;
        cmp-ok $node2.next, '=:=', $node.self, '$node2.next';

        # assert that the "next" argument must be a Series
        throws-like { $node.new(:$value, :$next) }, X::TypeCheck::Binding,
          'The :next argument must be of type Series';
    };
};

subtest 'infix ::', {
    # assert that infix :: accepts a Mu left operand
    my Mu $value;
    diag 'my Mu $value';

    my Series $series;
    diag 'my Series $series';
    subtest '$value :: Nil', {
        $series = $value :: Nil;
        isa-ok $series, Series:D, '$series = $value :: Nil';

        # assert that $!value is not bound to the provided container
        $value .= new;
        cmp-ok $series.value, '=:=', Mu,     '$series.value';
        cmp-ok $series.next,  '=:=', Series, '$series.next';
    };

    # assert that a concrete right operand initializes $!next
    my $node = $series;
    diag 'my $node = $series';
    subtest '$value :: $node', {
        my $series2 = $value :: $node;
        isa-ok $series2, Series:D, 'my $series2 = $value :: $node';

        # assert that $!next is not bound to the provided container
        $node = Any.new;
        cmp-ok $series2.next, '=:=', $series.self, '$series2.next';
    };

    # assert that infix:<::> is right associative
    subtest '$value :: $series :: Series', {
        my $series3 = $value :: $series :: Series;
        isa-ok $series3, Series:D, 'my $series3 = $value :: $series :: Series';
        cmp-ok $series3.next.value, '=:=', $series.self, '$series3.next.value';
    };

    # assert that the right operand must be Nil or of type Series
    throws-like { $value :: $node }, X::Multi::NoMatch,
      'The right operand must be Nil or of type Series';
};

subtest '.iterator', {
    my $series = 2 :: 1 :: Nil;
    diag 'my $series = 2 :: 1 :: Nil';

    my $iterator = $series.iterator;
    does-ok $iterator, Iterator:D, 'my $iterator = $series.iterator';
    cmp-ok $iterator.pull-one, '=:=', 2, '$iterator.pull-one';
    cmp-ok $iterator.pull-one, '=:=', 1, '$iterator.pull-one';
    cmp-ok $iterator.pull-one, '=:=', IterationEnd, '$iterator.pull-one';
};

subtest '.list', {
    my $series = 2 :: 1 :: Nil;
    diag 'my $series = 2 :: 1 :: Nil';

    my $list = $series.list;
    does-ok $list, List:D, 'my $list = $series.list';
    is-deeply $list, (2, 1), '$list contents';
};

done-testing;
