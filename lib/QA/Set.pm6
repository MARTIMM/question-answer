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
has Hash $.keys;
has Array $.questions;

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$!set-name!, Str :$title, Str :$description ) {

  $!title = $title // $!set-name.tclc;
  $!description = $description // $title;
  $!hide = False;
  $!keys = %();
  $!questions = [];

  self!load;
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( QA::Set:D :$set! ) {

  $!set-name = $set.set-name;
  $!title = $set.title;
  $!description = $set.description;
  $!hide = $set.hide;
  $!keys = $set.keys;
  $!questions = $set.questions;
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Hash:D :$set-data! ) {

  $!set-name = $set-data<set-name>;
  $!title = $set-data<title> // $!set-name.tclc;
  $!description = $set-data<description> // $!title;
  $!hide = $set-data<hide> // False;

  for @($set-data<questions>) -> $q {
    self.add-question(QA::Question.new( :name($q<name>), :qa-data($q)));
  }
}

#-------------------------------------------------------------------------------
method !load ( ) {

  $!qa-types .= instance;
  my Hash $set-data = $!qa-types.qa-load( $!set-name, :set);
  if ?$set-data {
    $!title = $set-data<title> // $!set-name.tclc;
    $!description = $set-data<description> // $!title;
    $!hide = $set-data<hide> // False;

    for @($set-data<questions>) -> $q {
#      my Str $name = $q<name>;#.delete;
#      my QA::Question $question .= new( :$name, :qa-data($q));
#      self.add-question($question);
      self.add-question(QA::Question.new( :name($q<name>), :qa-data($q)));
    }
  }
}

#-------------------------------------------------------------------------------
method add-question (
  QA::Question:D $question, Bool :$replace = False --> Bool
) {

  if $!keys{$question.name}:exists {
    if $replace {
      self.replace-question($question);
      True
    }

    else {
      False
    }
  }

  else {
    $!keys{$question.name} = $!questions.elems;
    $!questions.push: $question;
    True
  }
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

  if $!keys{$question.name}:exists {
    $!questions[$!keys{$question.name}] = $question;
  }

  else {
    $!keys{$question.name} = $!questions.elems;
    $!questions.push: $question;
  }
}

#-------------------------------------------------------------------------------
method set ( --> Hash ) {

  %( :$!set-name, :$!title, :$!description, :$!hide,
     questions => [map {.qa-data}, @$!questions // []]
  )
}

#-------------------------------------------------------------------------------
method save ( ) {
  $!qa-types .= instance;
  $!qa-types.qa-save( $!set-name, self.set, :set);
}

#-------------------------------------------------------------------------------
method remove ( --> Bool ) {
  if ?$!questions {
    $!questions = Nil;
    $!title = $!description = Str;

    $!qa-types .= instance;
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
