use v6.d;

use QA::Types;
use QA::Question;

#-------------------------------------------------------------------------------
unit class QA::Set:auth<github:MARTIMM>;
also does Iterable;

has QA::Types $!qa-types;

has Str $.set-name is required;
has Str $.title is rw;
has Str $.description is rw;
has Bool $.hide is rw;

# this QA::KV's keys and values. $!keys is to check the names and index
# into $!questions and $!questions is to keep order as it is input.
has Hash $!keys;
has Array $!questions;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$name, Str :$title, Str :$description ) {

  $!qa-types .= instance;

  $!set-name = $name;
  $!title = $title // $!set-name.tclc;
  $!description = $description // $title;
  $!keys = %();
  $!questions = [];
  $!hide = False;

  self!load;
}

#-------------------------------------------------------------------------------
method !load ( ) {

  my Hash $set = $!qa-types.qa-load( $!set-name, :set);
  if ?$set {
#    my Str $name = $!set-name;
    my Str $title = $set<title> // $!set-name.tclc;
    my Str $description = $set<description> // $title;

    for @($set<questions>) -> $q {
      my Str $name = $q<name>;#.delete;
      my QA::Question $question .= new( :$name, :qa-data($q));
      self.add-question($question);
    }
  }
}

#-------------------------------------------------------------------------------
method add-question ( QA::Question:D $question --> Bool ) {

  # check if key exists, don't overwrite
  return False if $!keys{$question.name}.defined;

  $!keys{$question.name} = $!questions.elems;
  $!questions.push: $question;

  True
}

#-------------------------------------------------------------------------------
method get-question ( Str $name --> QA::Question ) {

  $!questions[$!keys{$name}]
}

#-------------------------------------------------------------------------------
method get-questions ( --> Array ) {

  $!questions
}

#-------------------------------------------------------------------------------
method replace-question ( QA::Question:D $question ) {

  $!questions[$!keys{$question.name}] = $question;
}

#-------------------------------------------------------------------------------
method set ( --> Hash ) {

  %( :$!title, :$!description, :$!hide,
     questions => [map {.qa-data}, @$!questions]
  )
}

#-------------------------------------------------------------------------------
method save ( ) {
  $!qa-types.qa-save( $!set-name, self.set, :set);
}

#-------------------------------------------------------------------------------
method remove ( --> Bool ) {
  if ?$!questions {
    $!questions = Nil;
    $!title = $!description = Str;
    $!qa-types.qa-remove( $!set-name, :set);

    True
  }

  else {
    False
  }
}

#-------------------------------------------------------------------------------
# Iterator to be used in for {} statements returning questions from this set
=begin pod

  my $c := $set.clone;
  for $c -> QA::Question $question {
    ...;
  }

=end pod
method iterator ( ) {

  # Create anonymous class which does the Iterator role
  class :: does Iterator {
    has $!count = 0;
    has Array $.qdata is rw;

#    submethod BUILD (:$!pdata) { note $!pdata.elems; }

    method pull-one ( --> Mu ) {

      return $!count < $!qdata.elems
        ?? $!qdata[$!count++]
        !! IterationEnd;
    }

    # Create the object for this class and return it
  }.new(:qdata($!questions))
}
