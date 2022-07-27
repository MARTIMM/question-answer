use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk3::Label;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Switch;
use Gnome::Gtk3::Enums;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class QA::Gui::QASwitch;
also does QA::Gui::Value;

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
}

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # create a grid with checkbuttons
  my Gnome::Gtk3::Grid $switch-grid .= new;
  self.add-class( $switch-grid, 'QAGrid');

  # create a text input widget
  my Gnome::Gtk3::Switch $switch .= new;
#  $switch.set-hexpand(False);
  $switch.register-signal( self, 'input-change-handler', 'state-set', :$row);
  self.add-class( $switch, 'QASwitch');

  $switch-grid.attach( $switch, 0, 0, 1, 1);

  my Gnome::Gtk3::Label $label .= new(:text(''));
  $label.set-hexpand(True);
#  $label.set-justify(GTK_JUSTIFY_FILL);
#  $label.set-halign(GTK_ALIGN_START);
  $switch-grid.attach( $label, 1, 0, 1, 1);

  $switch-grid
}

#`{{
#-------------------------------------------------------------------------------
method get-value ( $switch --> Any ) {
  $switch.get-active.Bool;
}
}}

#-------------------------------------------------------------------------------
method set-value ( Any:D $switch-grid, $state ) {
  my Gnome::Gtk3::Switch() $switch = $switch-grid.get-child-at( 0, 0);
  $switch.set-active($state.Bool);
}

#`{{
#-------------------------------------------------------------------------------
method clear-value ( Any:D $switch ) {
}
}}

#-------------------------------------------------------------------------------
method input-change-handler (
  Int $state, Gnome::Gtk3::Switch() :_native-object($switch), :$row --> Int
) {
  my Gnome::Gtk3::Grid() $switch-grid = $switch.get-parent;
#  my Gnome::Gtk3::Switch $switch = $switch-grid.get-child-at-rk( 0, 0);

  self.process-widget-input(
    $switch-grid, $switch.get-active.Bool, $row, :!do-check
  );

  1
}
