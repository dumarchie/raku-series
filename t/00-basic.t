use v6.d;
use Test;

use lib 'lib';
use Series;

subtest 'method new', {
    subtest 'Series.new', {
        $_ := Series.new;
        isa-ok $_, Series:D, '$_ := Series.new';
        cmp-ok .Bool, '=:=', False,  '.Bool';
        cmp-ok .head, '=:=', Nil,    '.head';
        cmp-ok .next, '=:=', $_,     '.next';
        subtest '.iterator', {
            my $iter = .iterator;
            does-ok $iter, Iterator, 'my $iter = .iterator';
            cmp-ok $iter.pull-one, '=:=', IterationEnd, '$iter.pull-one';
        }
        is-deeply .list, Empty.List, '.list';
        is-deeply .gist, Empty.gist, '.gist';
        is .raku, 'Series.new',      '.raku';
    }

    cmp-ok Series.new(Empty), '=:=', Series.new, 'Series.new(Empty)';

    subtest 'Series.new($value)', {
        my $value = Mu.new;
        $_ := Series.new($value);
        isa-ok $_, Series:D, '$_ := Series.new($value)';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', $value<>,     '.head';
        cmp-ok .next, '=:=', Series.new,   '.next';
        subtest '.iterator', {
            my $iter = .iterator;
            does-ok $iter, Iterator, 'my $iter = .iterator';
            cmp-ok $iter.pull-one, '=:=', $value<>,     '$iter.pull-one';
            cmp-ok $iter.pull-one, '=:=', IterationEnd, '$iter.pull-one';
        }
    }

    subtest 'Series.new(1, 2, "answer" => 42)', {
        $_ := Series.new(1, 2, "answer" => 42);
        isa-ok $_, Series:D, '$_ := Series.new(1, 2, "answer" => 42)';
        cmp-ok .Bool, '=:=', True,                      '.Bool';
        cmp-ok .head, '=:=', 1,                         '.head';
        is-deeply .next, Series.new(2, "answer" => 42), '.next';
        is-deeply .list, (1, 2, "answer" => 42),        '.list';
        is-deeply .gist, (1, 2, "answer" => 42).gist,   '.gist';
        subtest '.raku', {
            my $code = .raku; diag $code;
            isa-ok $code, Str, 'my $code = .raku';
            is-deeply $code.EVAL, $_, '$code.EVAL';
        }
    }
}

subtest 'method bless(Mu :$value, Series :$next --> Series:D)', {
    # check attribute defaults
    my $series = Series.bless;
    isa-ok $series, Series:D, '$series = Series.bless';
    cmp-ok $series.value, '=:=', Mu,         '$series.value';
    cmp-ok $series.next,  '=:=', Series.new, '$series.next';

    # assert there's no method BUILD that may overwrite attributes
    my $value = Mu.new;
    throws-like { $series.BUILD(:$value) }, X::Method::NotFound,
      :method<BUILD>, :typename<Series>, "No method 'BUILD'";

    # assert attributes are initialized with the provided values
    my $series2 = Series.bless(:$value, next => $series);
    isa-ok $series2, Series:D,
      '$series2 = Series.bless(:$value, next => $series)';

    cmp-ok $series2.value, '=:=', $value<>,  '$series2.value';
    cmp-ok $series2.next,  '=:=', $series<>, '$series2.next';

    # assert the value of the "next" attribute is constrained to Series
    throws-like { Series.bless(next => 42) }, X::TypeCheck::Binding::Parameter,
      'Series.bless(next => 42)';
}

subtest 'infix ::', {
    my $value = Mu.new;
    subtest '$value :: Nil', {
        $_ := $value :: Nil;
        isa-ok $_, Series:D, '$_ := $value :: Nil';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', $value<>,     '.head';
        cmp-ok .next, '=:=', Series.new,   '.next';
    }

    my $next = (:answer(42) :: Nil);
    subtest '$value :: $next', {
        $_ := $value :: $next;
        isa-ok $_, Series:D, '$_ := $value :: $next';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', $value<>,     '.head';
        cmp-ok .next, '=:=', $next<>,      '.next';
    }

    my $example = '(1 :: 2 :: Nil) eqv Series.new(1, 2)';
    ok $example.EVAL, $example;
}

done-testing;
