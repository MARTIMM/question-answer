use v6.d;

use QA::Question;

#-------------------------------------------------------------------------------
unit class QA::Set:auth<github:MARTIMM>;
also does Iterable;

has Str $.name is required;
has Str $.title is rw;
has Str $.description is rw;
has Bool $.hide is rw;

# this QA::KV's keys and values. $!keys is to check the names and index
# into $!questions and $!questions is to keep order as it is input.
has Hash $!keys;
has Array $!questions;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$!name, Str :$title, Str :$description ) {

  $!title = $title // $!name.tclc;
  $!description = $description // $title;
  $!keys = %();
  $!questions = [];
  $!hide = False;
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
method get-questions ( --> Array ) {

  $!questions
}

#-------------------------------------------------------------------------------
method replace-question ( QA::Question:D $question ) {

  $!questions[$!keys{$question.name}] = $question;
}

#-------------------------------------------------------------------------------
method set ( --> Hash ) {

  %( :$!name, :$!title, :$!description, :$!hide,
     questions => [map {.qa-data}, @$!questions]
  )
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
