use v6.d;

use QA::Types;

#-------------------------------------------------------------------------------
unit class QA::Questionnaire:auth<github:MARTIMM>;
#also does Iterable;
#also does Iterator;

#-------------------------------------------------------------------------------
# sheets are filenames holding pages of sets
has Str $!qst-name is required;

# complete questionnaire and control
has Hash $!questionnaire;
has Bool $!is-modified = False;
has Bool $!versioned = False;
has Int $!version = 0;

# questionnaire's pages
has Hash $!pages;
has Array $!page-data;

# sets on the pages
has Hash $!sets;
has Array $!set-data;

#has Hash $!page;

# sheet dialog properties
has Int $.width is rw;
has Int $.height is rw;
has Hash $.button-map is rw;

has QA::Types $!qa-types;

#-------------------------------------------------------------------------------
#TM:1:new
=begin pod

Load the questionnaire from a file or copy it from the user provided data. Some defaults are set such as the width and height of the window wherein the questionnaire is shown.

The filename of the questionnaire is simple at first. Just a name with an extension depending on its format C<yaml>, C<toml> or C<json>. When versions are used, the name is extended with a version like so C<original-name:version.ext>. Further more the name C<original-name:'latest'.ext> is linked to the latest version.

  new (
    Str:D :$!qst-name, Hash :$sheet,
    Bool :$!versioned = False, Int :$!version = 0
  )

=item $!qst-name; The name of the file of the questionnaire
=item $sheet; A user provided questionnaire. If defined and not empty, the file described by $!qst-name is not loaded and the user data is used instead.
=item $versioned; If versioned is True, saving the data with C<.save()> will have a version number added to the filename starting from C<001> with a max of C<999> which should be sufficient. If False, it will take the original and replace the original. To prevent that, use C<.save-as()>.
=item $version; If a version is given, pick that version of the questionnaire. If undefined or 0 and $versioned is True, pick the latest version available.

=end pod
submethod BUILD (
  Str:D :$!qst-name, Hash :$sheet,
  Bool :$!versioned = False, Int :$!version = 0
) {

  # initialize types
  $!qa-types .= instance;
  self!load(:$sheet);
}

#-------------------------------------------------------------------------------
method !load ( Hash :$sheet is copy ) {

  # initialize sheets
  $!pages = %();
  $!page-data = [];

  $!questionnaire //= $!qa-types.qa-load(
    $!qst-name, :sheet, :$!versioned, :$!version
  ) // %();

  if ?$!questionnaire {
    $!width = $!questionnaire<width> // 0;
    $!height = $!questionnaire<height> // 0;
    $!button-map = $!questionnaire<button-map> // %();

    # the rest are pages
    for @($!questionnaire<pages>) -> $page {
      next unless ?$page;

      # get and save page properties
      if $page<page-name>:exists and ?$page<page-name> {

        $page<title> //= $page<page-name>.tclc;
        $page<description> //= $page<title>;
        $page<hide> //= False;
        $page<page-type> = ?$page<page-type>
          ?? QAPageType(QAPageType.enums{$page<page-type>} // QAContent)
          !! QAContent;

        $!pages{$page<page-name>} = $!page-data.elems;
        $!page-data.push: $page;
      }

      else {
        note "Name of page not defined, page skipped";
      }
    }
  }
}

#-------------------------------------------------------------------------------
method add-page (
  Str:D $page-name, Str :$title is copy = '', Str :$description is copy = '',
  Bool :$hide = False
  --> Bool
) {

  return False if $!pages{$page-name}:exists;

  $title //= $page-name.tclc;
  $description //= $title;

  $!set-data = [];
  my Hash $page = %( :$page-name, :$title, :$description, :$hide);

  $!pages{$page-name} = $!page-data.elems;
  $!page-data.push: $page;
  $!is-modified = True;

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
  $!is-modified = True;

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

  $!is-modified = True;

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

  return %() unless $!pages{$page-name}:exists;

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

  if $!is-modified {
    $!qa-types.qa-save(
      $!qst-name, %(:$!width, :$!height, :$!button-map, :pages($!page-data)),
      :sheet
    );

    $!is-modified = False;
  }
}

#-------------------------------------------------------------------------------
method save-as ( Str:D $new-sheet ) {

  $!qa-types.qa-save(
    $new-sheet, %(:$!width, :$!height, :$!button-map, :pages($!page-data)),
    :sheet
  );

  $!qst-name = $new-sheet;
  $!is-modified = False;
}

#-------------------------------------------------------------------------------
method remove ( --> Bool ) {

  if ?$!pages {
    $!pages = Nil;
    $!page-data = [];
    $!qa-types.qa-remove( $!qst-name, :sheet);
    $!is-modified = False;
    True
  }

  else {
    $!is-modified = False;
    False
  }

  # saving is unnecesary when questionnaire is completely wiped, also from disk
}

#-------------------------------------------------------------------------------
# Iterator to be used in for {} statements returning pages from this sheet
=begin pod

  my QA::Questionnaire $q := QA::Questionnaire.new(:qst-name<login>);
  …
  for $q -> Hash $page {
    note $page.keys;
    …;
  }

=end pod

# The loop operators search for the .iterator() method
method iterator ( QA::Questionnaire:D: ) {
  my $pdata = $!page-data;

  # Create anonymous class which does the Iterator role. This class
  # must have a pull-one() method
  my class :: does Iterator {
    has $!count = 0;
    method pull-one ( --> Mu ) {
      return $!count < $pdata.elems
        ?? $pdata[$!count++]
        !! IterationEnd;
    }

    # Create the object for this class because there
    # is a reference to an attribute $!page-data
  }.new
}

#`{{
method iterator ( QA::Questionnaire:D: ) {
  # Create anonymous class which does the Iterator role
  my class :: does Iterator {
    has $!count = 0;
    has Array $.pdata;

    submethod BUILD ( :$!pdata ) { note $!pdata.elems; }

    method pull-one ( --> Mu ) {
      return $!count < $!pdata.elems
        ?? $!pdata[$!count++]
        !! IterationEnd;
    }

    # Create the object for this class and return it
  }.new(:pdata($!page-data))
}
}}

