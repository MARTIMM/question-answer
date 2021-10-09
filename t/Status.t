use v6.d;
use Test;

use QA::Status;

#-------------------------------------------------------------------------------
subtest 'tap test', {
  my QA::Status $s .= instance;
  $s.tap( -> $x { is $x, 10, 'tap works'; } );

  sub p ( $x ) { is $x, 10, 'other tap works too'; }
  $s.tap(&p);

  $s.send(10);
}

#-------------------------------------------------------------------------------
done-testing;
