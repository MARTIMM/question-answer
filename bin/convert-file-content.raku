#!/usr/bin/env -S raku

use v6;

use JSON::Fast;
use Config::TOML;
use YAMLish;

#-------------------------------------------------------------------------------
sub MAIN (
  Str $in-file where (.IO.extension ~~ any(<json toml yaml>) and .IO.r),
  Str $out-file where .IO.extension ~~ any(<json toml yaml>),
) {
  my $in-type = $in-file.IO.extension;
  my $out-type = $out-file.IO.extension;

  my $data = data($in-file);
  data( $out-file, $data);
}

sub data ( Str:D $f, $data? is copy --> Any ) {
  my Bool $load = $data.defined ?? False !! True;

#  $f = IO.absolute;
  my $t = $f.IO.extension;

  given $t {
    when 'json' {
      if $load {
        $data = from-json($f.IO.slurp);
      }

      else {
        $f.IO.spurt(to-json($data));
      }
    }

    when 'toml' {
      if $load {
        $data = from-toml($f.IO.slurp);
      }

      else {
        $f.IO.spurt(to-toml($data));
      }
    }

    when 'yaml' {
      if $load {
        $data = load-yaml($f.IO.slurp);
      }

      else {
        $f.IO.spurt(save-yaml($data));
      }
    }
  }
}
