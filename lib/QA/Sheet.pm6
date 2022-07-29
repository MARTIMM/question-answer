use v6.d;

use QA::Types;

#-------------------------------------------------------------------------------
unit class QA::Sheet:auth<github:MARTIMM>;
also does Iterable;
#also does Iterator;

#-------------------------------------------------------------------------------
# sheets are filenames holding pages of sets
has Str $!sheet-name is required;

# this QA::Sheet's pages
has Hash $!pages;
has Array $!page-data;

has Hash $!sets;
has Array $!set-data;
has Iterator $!iterator;

has Hash $!page;

# sheet dialog properties
has Int $.width is rw;
has Int $.height is rw;
has Hash $.button-map is rw;

has QA::Types $!qa-types;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$!sheet-name, Hash :$sheet ) {

  # initialize types
  $!qa-types .= instance;
  self!load(:$sheet);
}

#-------------------------------------------------------------------------------
method !load ( Hash :$sheet is copy ) {

  # initialize sheets
  $!pages = %();
  $!page-data = [];

  $sheet //= $!qa-types.qa-load( $!sheet-name, :sheet);
  if ?$sheet {
    $!width = $sheet<width> // 0;
    $!height = $sheet<height> // 0;
    $!button-map = $sheet<button-map> // %();

    # the rest are pages
    for @($sheet<pages>) -> $h-page {
      next unless ?$h-page;

      # get and save page properties
      if $h-page<page-name>:exists and ?$h-page<page-name> {

        $h-page<title> //= $h-page<page-name>.tclc;
        $h-page<description> //= $h-page<title>;
        $h-page<hide> //= False;
        $h-page<page-type> = ?$h-page<page-type>
          ?? QAPageType(QAPageType.enums{$h-page<page-type>} // QAContent)
          !! QAContent;

        $!pages{$h-page<page-name>} = $!page-data.elems;
        $!page-data.push: $h-page;
      }

      else {
        note "Name of page not defined, page skipped";
      }
    }
  }
}

#-------------------------------------------------------------------------------
method add-page (
  Str:D $page-name, Str :$title = '', Str :$description = '',
  Bool :$hide = False
  --> Bool
) {

  return False if $!pages{$page-name}:exists;

  $title //= $page-name.tclc;
  $description //=$title;

  $!set-data = [];
  $!page = %( :$page-name, :$title, :$description, :$hide);

  $!pages{$page-name} = $!page-data.elems;
  $!page-data.push: $!page;

  True
}

#-------------------------------------------------------------------------------
method remove-page ( Str:D $page-name --> Bool ) {

  return False unless $!pages{$page-name}:exists;

  my Int $idx = $!pages{$page-name}:delete;
  $!page-data.splice( $idx, 1);
  for $!pages.keys -> $k {
    $!pages{$k}-- if $!pages{$k} > $idx;
  }

  True
}

#-------------------------------------------------------------------------------
multi method get-page ( Int:D $page-idx --> Hash ) {
  $page-idx < $!page-data.elems ?? $!page-data[$page-idx] !! %();
}

#-------------------------------------------------------------------------------
multi method get-page ( Str:D $page-name --> Hash ) {
  my Int $page-idx  = $!pages{$page-name}:exists ?? $!pages{$page-name} !! -1;
  $page-idx >= 0 ?? $!page-data[$page-idx] !!  %();
}

#-------------------------------------------------------------------------------
method get-sheet-list ( --> List ) {
  $!qa-types.qa-list(:sheet)
}

#-------------------------------------------------------------------------------
method add-set (
  Str:D $page-name, Str:D $set-name, Bool :$replace = False --> Bool
) {

  return False unless $!pages{$page-name}:exists;

  my Hash $new-set = $!qa-types.qa-load( $set-name, :set);
  return False unless ?$new-set;

  my Bool $ok = False;
  my Int $c = 0;
  my Bool $set-found = False;
  my Int $pidx = $!pages{$page-name};

  if $!page-data[$pidx]<sets>:exists {
    for @($!page-data[$pidx]<sets>) -> Hash $set {
      if $set<set-name> eq $set-name {
        $set-found = True;
        if $replace {
          $!page-data[$pidx]<sets>.splice( $c, 1, $new-set);
          $ok = True;
        }

        else {
          $ok = False;
        }
        last;
      }

      else {
        $c++;
      }
    }
  }

  unless $set-found {
    $!page-data[$pidx]<sets>.push: $new-set;
    $ok = True;
  }

  $ok
}

#-------------------------------------------------------------------------------
method remove-set ( Str:D $page-name, Str:D $set-name --> Bool ) {

  return False unless $!pages{$page-name}:exists;

  my Bool $ok = False;
  my Int $c = 0;
  my Int $pidx = $!pages{$page-name};

  if $!page-data[$pidx]<sets>:exists {
    for @($!page-data[$pidx]<sets>) -> Hash $set {
      if $set<set-name> eq $set-name {
        $!page-data[$pidx]<sets>.splice( $c, 1);
        $ok = True;
        last;
      }

      else {
        $c++;
      }
    }
  }

  $ok
}

#-------------------------------------------------------------------------------
method get-set ( Str:D $page-name, Str:D $set-name --> Hash ) {

  return False unless $!pages{$page-name}:exists;

  my Int $pidx = $!pages{$page-name};
  my Hash $set = %();

  if $!page-data[$pidx]<sets>:exists {
    for @($!page-data[$pidx]<sets>) -> Hash $s {
      if $s<set-name> eq $set-name {
        $set = $s;
        last;
      }
    }
  }

  $set
}

#-------------------------------------------------------------------------------
method save ( ) {

  $!qa-types.qa-save(
    $!sheet-name, %(:$!width, :$!height, :$!button-map, :pages($!page-data)),
    :sheet
  );
}

#-------------------------------------------------------------------------------
method save-as ( Str:D $new-sheet ) {

  $!qa-types.qa-save(
    $new-sheet, %(:$!width, :$!height, :$!button-map, :pages($!page-data)),
    :sheet
  );
  $!sheet-name = $new-sheet;
}

#-------------------------------------------------------------------------------
method remove ( --> Bool ) {

  if ?$!pages {
    $!pages = Nil;
    $!page-data = [];
    $!qa-types.qa-remove( $!sheet-name, :sheet);
    True
  }

  else {
    False
  }
}

#-------------------------------------------------------------------------------
# Iterator to be used in for {} statements returning pages from this sheet
=begin pod

  my $c := $sheet.clone;
  for $c -> Hash $page {
    note $page.keys;
    ...;
  }

=end pod
method iterator ( ) {

  # Create anonymous class which does the Iterator role
  class :: does Iterator {
    has $!count = 0;
    has Array $.pdata is rw;

#    submethod BUILD (:$!pdata) { note $!pdata.elems; }

    method pull-one ( --> Mu ) {

      return $!count < $!pdata.elems
        ?? $!pdata[$!count++]
        !! IterationEnd;
    }

    # Create the object for this class and return it
  }.new(:pdata($!page-data))
}
