use v6.d;

use Gnome::Gdk3::Events;

use Gnome::Gtk3::Entry;

use QA::Types;
use QA::Gui::Frame;
use QA::Question;
use QA::Gui::Value;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class QA::Gui::QAEntry;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
# Make attributes readable so that the roles can access them using self.question
has QA::Question $.question;
has Hash $.user-data-set-part;

#-------------------------------------------------------------------------------
submethod BUILD ( QA::Question:D :$!question, Hash:D :$!user-data-set-part ) { }

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # create a text input widget
  given my Gnome::Gtk3::Entry $entry .= new {
    self.add-class( $entry, 'QAEntry');

    .set-size-request( 70, 1);
    .set-hexpand(True);

    my Bool $visibility = ! $!question.invisible;
    .set-visibility($visibility);

    my Str $example = $!question.example;
    .set-placeholder-text($example) if ?$example;

    .register-signal( self, 'input-change-handler', 'focus-out-event', :$row);
  }

  $entry
}

#`{{
}}
#-------------------------------------------------------------------------------
method get-value ( $entry --> Any ) {
  $entry.get-text
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $entry, $text ) {
  $entry.set-text($text) if ?$text;
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $entry ) {
  $entry.set-text('');
}

#-------------------------------------------------------------------------------
method check-value ( Str $input --> Str ) {
  my Str $message;
  my Int $nc = $input.chars;
  if ?$!question.minimum and $nc < $!question.minimum {
    $message = "Minimum number of characters = $!question.minimum()";
  }

  elsif ?$!question.maximum and $nc > $!question.maximum {
    $message = "Maximum number of characters = $!question.maximum()";
  }

  $message
}

#-------------------------------------------------------------------------------
method input-change-handler (
  N-GdkEventFocus $no, :_widget($entry), Int() :$row --> Int
) {

  self.process-widget-input( $entry, $entry.get-text, $row, :do-check);

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}
