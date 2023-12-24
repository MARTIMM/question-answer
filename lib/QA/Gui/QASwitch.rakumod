use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Switch:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class QA::Gui::QASwitch;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # reset constraints when used wrong
  $!question.repeatable = False;
  $!question.selectlist = [];

  # create a grid with checkbuttons
  my Gnome::Gtk4::Grid $switch-grid .= new;
  self.add-class( $switch-grid, 'QAGrid');

  # create a text input widget
  my Gnome::Gtk4::Switch $switch .= new;
#  $switch.set-hexpand(False);
  $switch.register-signal( self, 'input-change-handler', 'state-set', :$row);
  self.add-class( $switch, 'QASwitch');

  $switch-grid.attach( $switch, 0, 0, 1, 1);

  my Gnome::Gtk4::Label $label .= new(:text(''));
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
  my Gnome::Gtk4::Switch() $switch = $switch-grid.get-child-at( 0, 0);
  $switch.set-active($state.Bool);
}

#`{{
#-------------------------------------------------------------------------------
method clear-value ( Any:D $switch ) {
}
}}

#-------------------------------------------------------------------------------
method input-change-handler (
  Int $state, Gnome::Gtk4::Switch() :_native-object($switch), :$row --> Int
) {
  my Gnome::Gtk4::Grid() $switch-grid = $switch.get-parent;
#  my Gnome::Gtk4::Switch $switch = $switch-grid.get-child-at-rk( 0, 0);

  self.process-widget-input(
    $switch-grid, $switch.get-active.Bool, $row, :!do-check
  );

  1
}
