use v6.d;
use Test;

use lib 'lib';
use Series;

subtest 'multi method new( --> Series:D)', {
    my $code = 'Series.new';
    $_ := $code.EVAL;
    isa-ok $_, Series:D, $code;
    cmp-ok $code.EVAL, '=:=', $_, "$code always returns the same object";
    cmp-ok .Bool, '=:=', False, '.Bool'; # it's never new ;)
    cmp-ok .head, '=:=', Nil,   '.head';
    cmp-ok .next, '=:=', $_,    '.next';
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

subtest 'method insert(Mu \value --> Series:D)', {
    my $code   = 'Series.insert($var)';
    my $var    = Mu.new;
    my $series = $code.EVAL;
    isa-ok $series, Series:D, "\$series = $code";
    cmp-ok $series.head, '=:=', $var<>,     '$series.head';
    cmp-ok $series.next, '=:=', Series.new, '$series.next';

    my $code2   = '$series.insert(Empty)';
    my $series2 = $code2.EVAL;
    isa-ok $series2, Series:D, "\$series2 = $code2";
    cmp-ok $series2.head, '=:=', Empty,     '$series2.head';
    cmp-ok $series2.next, '=:=', $series<>, '$series2.next';
}

subtest 'method bless(Mu :$value, Series :$next --> Series:D)', {
    my $code   = 'Series.bless';
    my $series = $code.EVAL;
    isa-ok $series, Series:D, "\$series = $code";
    cmp-ok $series.head, '=:=', Mu,         '$series.head';
    cmp-ok $series.next, '=:=', Series.new, '$series.next';

    # assert there's no method BUILD that may overwrite attributes
    my $var = Mu.new;
    throws-like { $series.BUILD(value => $var) }, X::Method::NotFound,
      :method<BUILD>, :typename<Series>, "No method 'BUILD'";

    # assert attributes are initialized with the provided values
    my $code2   = 'Series.bless(value => $var, next => $series)';
    my $series2 = $code2.EVAL;
    isa-ok $series2, Series:D, "\$series2 = $code2";
    cmp-ok $series2.head, '=:=', $var<>,    '$series2.head';
    cmp-ok $series2.next, '=:=', $series<>, '$series2.next';

    # assert the value of the "next" attribute is constrained to Series
    my $code3 = 'Series.bless(next => 42)';
    throws-like $code3, X::TypeCheck::Binding::Parameter, $code3;
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

is-deeply series.list, values, '.list';

is series.gist, values.gist, '.gist';

subtest '.raku', {
    is .EVAL.raku, $_, "$_.raku" for (
      'Series.new',
      '(1 :: 2 :: Series)'
    );
}

done-testing;
