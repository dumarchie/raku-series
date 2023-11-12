use v6.d;
use Test;

use lib 'lib';
use Series;

subtest 'method new', {
    subtest 'Series.new', {
        $_ := Series.new;
        isa-ok $_, Series:D, '$_ := Series.new';
        cmp-ok .Bool, '=:=', False,        '.Bool';
        cmp-ok .head, '=:=', Nil,          '.head';
        cmp-ok .next, '=:=', $_,           '.next';
    }

    subtest 'Series.new(Empty)', {
        $_ := Series.new(Empty);
        isa-ok $_, Series:D, '$_ := Series.new(Empty)';
        cmp-ok .Bool, '=:=', False,        '.Bool';
        cmp-ok .head, '=:=', Nil,          '.head';
        cmp-ok .next, '=:=', $_,           '.next';
    }

    subtest 'Series.new($value)', {
        my $value = Mu.new;
        $_ := Series.new($value);
        isa-ok $_, Series:D, '$_ := Series.new($value)';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', $value<>,     '.head';
        cmp-ok .next, '=:=', Series.new,   '.next';
    }

    subtest 'Series.new(1, 2, 3)', {
        $_ := Series.new(1, 2, 3);
        isa-ok $_, Series:D, '$_ := Series.new(1, 2, 3)';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', 1,            '.head';
        is-deeply .next, Series.new(2, 3), '.next';
    }
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

    my $next = 2 :: Nil;
    subtest '$value :: $next', {
        $_ := $value :: $next;
        isa-ok $_, Series:D, '$_ := $value :: $next';
        cmp-ok .Bool, '=:=', True,         '.Bool';
        cmp-ok .head, '=:=', $value<>,     '.head';
        cmp-ok .next, '=:=', $next<>,      '.next';
    }

    my $example = '1 :: 2 :: Nil eqv Series.new(1, 2)';
    ok $example.EVAL, $example;
}

subtest '.iterator', {
    $_ = Mu.new :: Nil;
    my $iterator = .iterator;
    does-ok $iterator, Iterator, 'my $iterator = .iterator';
    cmp-ok $iterator.pull-one, '=:=', .head,        '$iterator.pull-one';
    cmp-ok $iterator.pull-one, '=:=', IterationEnd, '$iterator.pull-one';
}

done-testing;
