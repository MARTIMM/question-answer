#!/usr/bin/env -S raku

use v6;

# try some cro.services way of writing code
# https://cro.services/docs/reference/cro-http-router
sub f ( Callable $r ) {
#  my @sig = r.signature;
#  note @sig.WHAT, ', ', @sig[0].WHAT, ', ', @sig[0].flat[0].WHAT;

  given $r.arity {
    when 1 {
      # TODO how do I know that I must send 'abc def'?
      $r('abc def');
    }

    when 2 {
      $r( 'abc', 'def');
    }
  }
}

# sub f accepts a block
f -> 'abc def' { note 'abc def'; }
f -> 'abc', 'def' { note 'abc, def'; }
