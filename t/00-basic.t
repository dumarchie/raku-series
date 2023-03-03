use Test;

use lib 'lib';
use Series;

subtest 'named argument constructor', {
    # assert that the constructor requires a value
    my Series $node;
    diag 'my Series $node';
    throws-like { $node .= new }, X::Attribute::Required, name => '$!value',
      'The :value argument is required';

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
        throws-like { $node.new(:$value, :$next) }, X::TypeCheck::Assignment,
          'The :next argument must be of type Series';
    };
};

done-testing;
