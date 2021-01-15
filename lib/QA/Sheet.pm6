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
submethod BUILD ( Str:D :$!sheet-name ) {

  # initialize types
  $!qa-types .= instance;
  self!load;
}

#-------------------------------------------------------------------------------
method !load ( ) {

  # initialize sheets
  $!pages = %();
  $!page-data = [];

  my Hash $sheet = $!qa-types.qa-load( $!sheet-name, :sheet);
  if ?$sheet {
    $!width = $sheet<width> // 0;# // 300;
    $!height = $sheet<height> // 0;# // 300;
    $!button-map = $sheet<button-map> // %();

    # the rest are pages
    for @($sheet<pages>) -> $h-page is copy {
      next unless ?$h-page;

      # get and save page properties
      if $h-page<name>:exists and ?$h-page<name> {

        $h-page<title> //= $h-page<name>.tclc;
        $h-page<description> //= $h-page<title>;
        $h-page<hide> //= False;
        $h-page<page-type> = ?$h-page<page-type>
          ?? QAPageType(QAPageType.enums{$h-page<page-type>} // QAContent)
          !! QAContent;

        $!pages{$h-page<name>} = $!page-data.elems;
        $!page-data.push: $h-page;
      }

      else {
        note "Name of page not defined, page skipped";
      }
    }
  }
}

#-------------------------------------------------------------------------------
method new-page (
  Str:D :$name, Str :$title = '', Str :$description = '',
  Bool :$hide = False
  --> Bool
) {

  return False if $!pages{$name}:exists;

  $title //= $name.tclc;
  $description //=$title;

  $!set-data = [];
  $!page = %( :$name, :$title, :$description, :$hide);

  $!pages{$name} = $!page-data.elems;
  $!page-data.push: $!page;

  True
}

#-------------------------------------------------------------------------------
method add-set ( Str:D :$set-name --> Bool ) {

  my Hash $set = $!qa-types.qa-load( $set-name, :set);
  if ?$set {
    # add set name for lookup and manips
    $set<name> = $set-name;
    $!set-data.push: $set;
    $!page<sets> = $!set-data;

    True
  }

  else {
    False
  }
}

#-------------------------------------------------------------------------------
method remove-set ( Str:D :$set-name --> Bool ) {
  my Bool $ok = False;
  my Int $c = 0;
  for @$!set-data -> Hash $sd {
    if $sd<name> eq $set-name {
      $!set-data.splice( $c, 1);
      $ok = True;
      last;
    }

    else {
      $c++;
    }
  }

  $ok
}

#-------------------------------------------------------------------------------
method save ( ) {
  $!qa-types.qa-save( $!sheet-name, %( :pages($!page-data)), :sheet);
}

#-------------------------------------------------------------------------------
method save-as ( Str:D $new-sheet ) {

  $!qa-types.qa-save( $new-sheet, %( :pages($!page-data)), :sheet);
  $!sheet-name = $new-sheet;
}

#-------------------------------------------------------------------------------
method delete-page ( :$name --> Bool ) {

#TODO yes/no message using 'Bool :$gui = False' argument

  return False unless $!pages{$name}:exists;

  $!page-data.splice( $!pages{$name}, 1);
  for $!pages.keys -> $k {
    $!pages{$k}-- if $!pages{$k} > $!pages{$name}
  }

  $!pages{$name}:delete;
  True
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

#-------------------------------------------------------------------------------
multi method get-page ( Int $page-idx --> Hash ) {
  $page-idx < $!page-data.elems ?? $!page-data[$page-idx] !! %();
}

#-------------------------------------------------------------------------------
multi method get-page ( Str $page-name --> Hash ) {
  my Int $page-idx  = $!pages{$page-name}:exists ?? $!pages{$page-name} !! -1;
  $page-idx >= 0 ?? $!page-data[$page-idx] !!  %();
}

#-------------------------------------------------------------------------------
method get-sheet-list ( --> List ) {
  $!qa-types.qa-list(:sheet)
}
