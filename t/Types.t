use v6;
use Test;
use Gnome::Gtk3::Entry;
use QA::Types;

#-------------------------------------------------------------------------------
#enum DE <SET SHEET UDATA>;
#my @dirs = <t/Data/Sets t/Data/Sheets t/Data/Userdata>;
#for @dirs -> $d {
#  mkdir $d, 0o700 unless $d.IO.e;
#}

class EH {
  method m1 ( ) { note 'cfg-k1'; };
  method m2 ( ) { note 'cfg-k2'; };
}

my EH $eh .= new;
my QA::Types $qa-types;

my @opts = ( :set, :sheet, :userdata);
my @types = < set qst data >;
my Hash $data;

#-------------------------------------------------------------------------------
subtest 'QA locations', {
  # set a few values before initializing
  given $qa-types {
    .data-file-type(QAYAML);
    nok .get-extension.defined, '.get-extension()';

    is $qa-types.get-root-path,
        $*DISTRO.is-win ?? "$*HOME/dataDir/Types" !! "$*HOME/.config/Types",
        '.get-root-path()';

    mkdir './t/Data/MyRoot', 0o700;
    .set-root-path('./t/Data/MyRoot');
    is $qa-types.get-root-path, './t/Data/MyRoot', '.get-root-path()';

    .set-extension('my-ext');
    is .get-file-path( 'config', :set), './t/Data/MyRoot/config.my-extset',
       '.set-extension() / .get-file-path()';
  }
}

#-------------------------------------------------------------------------------
subtest 'ISA test', {
  $qa-types.set-extension(Str);
  $qa-types .= instance;
  isa-ok $qa-types, QA::Types, '.instance()';
}

#-------------------------------------------------------------------------------
subtest 'Handler admin', {

  $qa-types.set-check-handler( 'cfg-k1', $eh, 'm1', :o1(1));
  is $qa-types.get-check-handler('cfg-k1'), [ $eh, 'm1', :o1(1)],
    '.set-check-handler() / .get-check-handler()';

  $qa-types.set-action-handler( 'cfg-k2', $eh, 'm2', :o2(2));
  is $qa-types.get-action-handler('cfg-k2'), [ $eh, 'm2', :o2(2)],
    '.set-action-handler() / .get-action-handler()';

  my Gnome::Gtk3::Entry $e .= new;
  $qa-types.set-widget-object( 'e-key', $e);
  is $qa-types.get-widget-object('e-key'), $e,
    '.set-widget-object() / .get-widget-object()'
}

#-------------------------------------------------------------------------------
subtest 'Save and load', {
  for <yaml json toml> -> $ftype {
    my Str $fname = "ftest";

    if $ftype eq 'yaml' {
      $qa-types.data-file-type(QAYAML);
    }

    elsif $ftype eq 'toml' {
      $qa-types.data-file-type(QATOML);
    }

    elsif $ftype eq 'json' {
      $qa-types.data-file-type(QAJSON);
    }

    for ^3 -> $di {
      $data = %( :a($ftype), @opts[$di]);
      $qa-types.qa-save( $fname, $data, |@opts[$di]);
      ok "./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]".IO.e,
        ".qa-save\(:@opts[$di].key()) ./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]";

      my Hash $d = $qa-types.qa-load( $fname, |@opts[$di]);
      is $d<a>, $ftype, ".qa-load\(:@opts[$di].key()) $ftype";
    }
  }
}

#-------------------------------------------------------------------------------
subtest 'Save and load versions', {
  for <yaml json toml> -> $ftype {
    my Str $fname = "ftest";

    if $ftype eq 'yaml' {
      $qa-types.data-file-type(QAYAML);
    }

    elsif $ftype eq 'toml' {
      $qa-types.data-file-type(QATOML);
    }

    elsif $ftype eq 'json' {
      $qa-types.data-file-type(QAJSON);
    }

    for ^3 -> $di {
      $data = %( :a($ftype), @opts[$di]);
      $qa-types.qa-save( $fname, $data, |@opts[$di], :versioned);
      ok "./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]".IO.e,
        ".qa-save\(:@opts[$di].key()) ./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]";

      my Hash $d = $qa-types.qa-load( $fname, |@opts[$di], :versioned);
      is $d<a>, $ftype, ".qa-load\(:@opts[$di].key()) $ftype";
    }
  }

#`{{
  $data = %( :a<yaml>);
  $qa-types.qa-save( 'abc', $data, :sheet);
  ok (@dirs[SHEET] ~ '/abc.yaml').IO.e, '.save(:sheet) yaml';

  $qa-types.qa-save( 'def', $data, :set);
  ok (@dirs[SET] ~ '/def.yaml').IO.e, '.save(:set) yaml';

  $data = %( :a<toml>);
  $qa-types.data-file-type(QATOML);
  $qa-types.qa-save( 'abc', $data, :sheet);
  ok (@dirs[SHEET] ~ '/abc.toml').IO.e, '.save(:sheet) toml';

  $data = $qa-types.qa-load( 'abc', :sheet);
  is $data<a>, 'toml', '.load(:sheet) toml';

  $qa-types.data-file-type(QAYAML);
  $data = $qa-types.qa-load( 'def', :set);
  is $data<a>, 'yaml', '.load(:set) yaml';
}}
}

#-------------------------------------------------------------------------------
subtest 'Miscellenous', {
#  is-deeply $qa-types.qa-list(:set).sort, <f-json f-toml f-yaml>, '.qa-list()';

  for <yaml json toml> -> $ftype {
    my Str $fname = "ftest";

    if $ftype eq 'yaml' {
      $qa-types.data-file-type(QAYAML);
    }

    elsif $ftype eq 'toml' {
      $qa-types.data-file-type(QATOML);
    }

    elsif $ftype eq 'json' {
      $qa-types.data-file-type(QAJSON);
    }

    for ^3 -> $di {
      $qa-types.qa-remove( $fname, |@opts[$di]);
      nok "./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]".IO.e,
        ".qa-remove\(:@opts[$di].key()) ./t/Data/MyRoot/$fname.$ftype\-qa@types[$di]";

      # remove rest if any
      if $qa-types.qa-remove( $fname ~ ':latest', |@opts[$di]) {
        my Int $version = 1;
        while $qa-types.qa-remove(
          "f-$ftype:" ~ $version.fmt('%03d'), |@opts[$di]
        ) {
          $version++;
        }
      }
    }
  }
}

#-------------------------------------------------------------------------------
unlink './t/Data/MyRoot';
done-testing
