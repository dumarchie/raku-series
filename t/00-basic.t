use v6.d;
use Test;

use lib 'lib';
use Series;

subtest 'empty series', {
    cmp-ok Series.head, '=:=', Nil, 'Series.head';

    my $series := Series.next;
    isa-ok $series, Series:D, '$series := Series.next';
    cmp-ok $series.Bool, '===', False,   '$series.Bool';
    cmp-ok $series.head, '=:=', Nil,     '$series.head';
    cmp-ok $series.next, '=:=', $series, '$series.next';
    cmp-ok Series.new,   '=:=', $series, 'Series.new';
}

subtest 'method insert(Mu \value --> Series:D)', {
    my \value  = Mu.new;
    my $code   = 'Series.insert($var)';
    my $var    = value;
    my $series = $code.EVAL;
    isa-ok $series, Series:D, "\$series = $code";

    $var = 42;
    cmp-ok $series.head, '=:=', value,      '$series.head';
    cmp-ok $series.next, '=:=', Series.new, '$series.next';

    my $code2   = '$series.insert(Empty)';
    my $series2 = $code2.EVAL;
    isa-ok $series2, Series:D, "\$series2 = $code2";
    cmp-ok $series2.head, '=:=', Empty,     '$series2.head';
    cmp-ok $series2.next, '=:=', $series<>, '$series2.next';
}

subtest 'sub infix:<::>(Mu \value, Series \next --> Series:D)', {
    subtest my $code = '$var :: Series', {
        my $var = Mu.new;
        $_ := $code.EVAL;
        isa-ok $_, Series:D;
        cmp-ok .Bool, '=:=', True,       '.Bool';
        cmp-ok .head, '=:=', $var<>,     '.head';
        cmp-ok .next, '=:=', Series.new, '.next';
    }

    subtest 'operator associativity', {
        my $code = '1 :: 2 :: $next';
        my $next = (3 :: Series);
        $_ := $code.EVAL;
        isa-ok $_, Series:D, $code;
        cmp-ok .head, '=:=', 1, '.head';
        subtest '.next', {
            $_ := .next;
            isa-ok $_, Series:D;
            cmp-ok .head, '=:=', 2,       '.head';
            cmp-ok .next, '=:=', $next<>, '.next';
        }
    }

    subtest 'operator precedence', {
        ok (not 0 :: Series).head, 'precedence is less than that of prefix not';
        isa-ok (0, 42 :: Series), List, 'precedence is same as that of infix ,';
    }
}

subtest 'method new', {
    my $code = 'Series.new(Empty)';
    cmp-ok $code.EVAL, '=:=', Series.new, $code;

    my $var = Mu.new;
    subtest $code = 'Series.new($var)', {
        $_ := $code.EVAL;
        isa-ok $_, Series:D;
        cmp-ok .head, '=:=', $var<>,     '.head';
        cmp-ok .next, '=:=', Series.new, '.next';
    }

    subtest $code = 'Series.new($var, 2, 3)', {
        $_ := $code.EVAL;
        isa-ok $_, Series:D;
        cmp-ok    .head, '=:=', $var<>,    '.head';
        is-deeply .next, Series.new(2, 3), '.next';
    }
}

my \values = 1, 2, 3;
my \series = Series.new(|values);

subtest '.elems', {
    cmp-ok Series.elems, '==', 0, 'Series.elems';
    cmp-ok series.elems, '==', 3, 'series.elems';
}

subtest '.list', {
    is-deeply Series.list, List.new, 'Series.list';
    is-deeply series.list, values,   'series.list';
}

is series.gist, values.gist, '.gist';

subtest '.raku', {
    is .EVAL.raku, $_, "$_.raku" for (
      'Series.new',
      '(1 :: 2 :: Series)'
    );
}

# To check lazy evaluation
my class Items does Iterable does Iterator {
    has int $.last;
    has int $.iterated;

    method iterator() { self }

    method pull-one() {
        $!iterated++ < $!last ?? $!iterated !! IterationEnd;
    }
}

subtest 'method prepend', {
    subtest 'Series.prepend(items)', {
        my \items = Items.new;
        $_ := Series.prepend(items);
        isa-ok .VAR, Proxy, 'Series.prepend(items) returns a Proxy';
        throws-like {
            $_ = 42;
        }, X::AdHoc, message => 'Cannot assign to an immutable Series',
          'The proxy cannot be assigned to';

        my $node = (42 :: $_);
        isa-ok $node, Series:D, '(value :: $_) returns a series';
        is items.iterated, 0, 'The items have not been iterated';

        cmp-ok .self, '=:=', Series.new,
          'The proxy evaluates to the empty series if there are no items';
    }

    subtest 'series.prepend(items)', {
        my \series = Series.new(3);
        my \items = Items.new(last => 2);
        $_ := series.prepend(items);
        isa-ok .VAR, Proxy,   'series.prepend(items) returns a Proxy';
        is items.iterated, 0, 'The items have not been iterated';
        isa-ok $_, Series:D,  'The proxy evaluates to a Series';
        is items.iterated, 1, 'Evaluation requires the first of the items';

        my \head = .iterator.pull-one;
        is items.iterated, 1,
          '.iterator.pull-one does not require subsequent items';

        is-deeply $_, Series.new(1, 2, 3),
          'The items are prepended to the original series';
    }
}

done-testing;
