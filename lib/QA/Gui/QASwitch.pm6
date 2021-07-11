use v6.d;

use Gnome::Gtk3::Switch;

use QA::Types;
use QA::Question;
use QA::Gui::ValueTools;
use QA::Gui::SingleValue;

#-------------------------------------------------------------------------------
unit class QA::Gui::QASwitch;
also does QA::Gui::SingleValue;
also does QA::Gui::ValueTools;

#-------------------------------------------------------------------------------
# Make attributes readable so that the roles can access them using self.question
has QA::Question $.question;
has Hash $.user-data-set-part;

#-------------------------------------------------------------------------------
# this widget is not repeatable and cannot have a combobox to category
# the choice of the input

submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part
) {
  $!question.repeatable = False;
  $!question.selectlist = [];
  self.initialize;
}

#-------------------------------------------------------------------------------
method create-widget ( --> Any ) {

  # create a text input widget
  my Gnome::Gtk3::Switch $switch .= new;
  $switch.set-hexpand(False);
  $switch.register-signal( self, 'changed-state', 'state-set');
  self.add-class( $switch, 'QASwitch');

  $switch
}

#-------------------------------------------------------------------------------
method get-value ( $switch --> Any ) {
  $switch.get-active.Bool;
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $switch, $state ) {
  $switch.set-active($state.Bool);
}

#-------------------------------------------------------------------------------
method changed-state ( Int $state, :_widget($switch) ) {
  self.process-widget-signal( $switch, :!do-check, :input($state.Bool));
}
