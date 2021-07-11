#!/usr/bin/env -S raku

use v6;

role R[Str $s]   { method role-type { print $s, ' ---> '; } };
role R[Int $i]   { method role-type { print $i, ' ---> '; } };
role R[Array $a] { method role-type { print $a.join(', '), ' ---> '; } };
role R['abc']    { method role-type { print '>> abc', ' ---> '; } };

class X {
  method new ( Int :$select, |c ) {
    print "select {$select % 4 }: ";

    given $select % 4 {
      when 0 {
        self.bless(|c) but R['def'];
      }

      when 1 {
        self.bless(|c) but R[42];
      }

      when 2 {
        self.bless(|c) but R[[^10]];
      }

      when 3 {
        self.bless(|c) but R['abc'];
      }
    }
  }
}

my X $x1 .= new(:10select);
$x1.role-type;
$x1.^name.say;

my X $x2 .= new(:11select);
$x2.role-type;
$x2.^name.say;

$x2 = X.new(:12select);
$x2.role-type;
$x2.^name.say;

# roles are added, not reset!
$x2 .= new(:13select);
$x2.role-type;
$x2.^name.say;
