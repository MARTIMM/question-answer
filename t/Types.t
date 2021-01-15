use v6;
use Test;
use Gnome::Gtk3::Entry;
use QA::Types;

#-------------------------------------------------------------------------------
enum DE <SET SHEET UDATA>;
my @dirs = <t/Data/Sets t/Data/Sheets t/Data/Userdata>;
for @dirs -> $d {
  mkdir $d, 0o700 unless $d.IO.e;
}

class EH {
  method m1 ( ) { note 'cfg-k1'; };
  method m2 ( ) { note 'cfg-k2'; };
}

my EH $eh .= new;

# set a few values before initializing
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata(@dirs[UDATA]);
  .cfgloc-sheet(@dirs[SHEET]);
  .cfgloc-set(@dirs[SET]);
}

#-------------------------------------------------------------------------------
subtest 'ISA test', {
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
  my @opts = ( :set, :sheet, :userdata);
  my Hash $data;

  for <yaml json toml> -> $ftype {
    my Str $fname = "f-$ftype";

    if $ftype eq 'yaml' {
      $qa-types.data-file-type(QAYAML);
    }

    elsif $ftype eq 'toml' {
      $qa-types.data-file-type(QATOML);
    }

    elsif $ftype eq 'json' {
      $qa-types.data-file-type(QAJSON);
    }

    for ( SET, SHEET, UDATA) -> $di {
      $data = %( :a($ftype), @opts[$di]);
      $qa-types.qa-save( $fname, $data, |@opts[$di]);
      ok (@dirs[$di] ~ "/$fname.$ftype").IO.e,
        ".save\(:@opts[$di].key()) @dirs[$di]/$fname.$ftype";

      my Hash $d = $qa-types.qa-load( $fname, |@opts[$di]);
      is $d<a>, $ftype, ".load\(:@opts[$di].key()) $ftype";
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
  is-deeply $qa-types.qa-list(:set).sort, <f-json f-toml f-yaml>, '.qa-list()';

  my @opts = ( :set, :sheet, :userdata);
  for <yaml json toml> -> $ftype {
    my Str $fname = "f-$ftype";

    if $ftype eq 'yaml' {
      $qa-types.data-file-type(QAYAML);
    }

    elsif $ftype eq 'toml' {
      $qa-types.data-file-type(QATOML);
    }

    elsif $ftype eq 'json' {
      $qa-types.data-file-type(QAJSON);
    }

    for ( SET, SHEET, UDATA) -> $di {
      $qa-types.qa-remove( "f-$ftype", |@opts[$di]);
      ok "@dirs[SET]/f-$ftype.$ftype".IO ~~ :!e,
        ".qa-remove\(:@opts[$di].key()) $ftype";
    }
  }
}

#-------------------------------------------------------------------------------
done-testing
