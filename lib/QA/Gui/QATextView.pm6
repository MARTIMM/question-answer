use v6.d;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;
use Gnome::Gtk3::TextIter;

use Gnome::Gdk3::Events;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

#-------------------------------------------------------------------------------
unit class QA::Gui::QATextView;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
# take a Num for word count because ∞ and -∞ is a Num
has Num() ( $!maximum, $!minimum);

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # reset constraints when used wrong
  $!maximum = $!question.options<maximum> // ∞;
  $!minimum = $!question.options<minimum> // -∞;

  $!question.repeatable = False;

  # create a text input widget
  with my Gnome::Gtk3::TextView $textview .= new {
    .set-hexpand(True);
    .set-size-request( 1, $!question.height // 50);
    .set-wrap-mode(GTK_WRAP_WORD);
    .set-border-width(1);
    .register-signal( self, 'input-change-handler', 'focus-out-event', :$row);
  }

  self.add-class( $textview, 'QATextView');

  $textview
}

#-------------------------------------------------------------------------------
method !get-value ( $textview --> Any ) {
  my Gnome::Gtk3::TextBuffer $textbuffer .= new(
    :native-object($textview.get-buffer)
  );

  my Gnome::Gtk3::TextIter $start = $textbuffer.get-start-iter;
  my Gnome::Gtk3::TextIter $end = $textbuffer.get-end-iter;
  $textbuffer.get-text( $start, $end, True)
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $textview, $text ) {
  if ?$text {
    my Gnome::Gtk3::TextBuffer $textbuffer .= new(
      :native-object($textview.get-buffer)
    );

    $textbuffer.set-text($text);
  }
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $textview ) {
  my Gnome::Gtk3::TextBuffer $textbuffer .= new(
    :native-object($textview.get-buffer)
  );

  $textbuffer.set-text('');
}

#-------------------------------------------------------------------------------
method check-value ( Str $input --> Str ) {
  my Str $message;
  my Int $nw = $input.comb(/\w+/).elems;
  if $nw < $!minimum {
    $message = "Minimum number of words = $!minimum";
  }

  elsif $nw > $!maximum {
    $message = "Maximum number of words = $!maximum";
  }

  $message
}

#-------------------------------------------------------------------------------
method input-change-handler (
  N-GdkEventFocus() $, Gnome::Gtk3::TextView() :_native-object($textview),
  Int() :$row --> Int
) {
  self.process-widget-input(
   $textview, self!get-value($textview), $row, :do-check
  );

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}
