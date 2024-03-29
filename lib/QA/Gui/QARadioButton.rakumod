use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::RadioButton:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::QARadioButton;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # reset constraints when used wrong
  $!question.repeatable = False;
  $!question.selectlist = [];

  # create a grid with radiobuttons
  my Gnome::Gtk4::Grid $button-grid .= new;
  self.add-class( $button-grid, 'QAGrid');

  my Int $button-grid-row = 0;
  my Gnome::Gtk4::RadioButton $rb-first;
  for @($!question.fieldlist) -> $label {
    my Gnome::Gtk4::RadioButton $rb .= new(:$label);
    $rb.set-hexpand(True);
    self.add-class( $rb, 'QARadioButton');

    # join the group of the first button
    $rb.join-group($rb-first) if ?$rb-first;

    # set first button in the group
    $rb-first = $rb unless ?$rb-first;
    $button-grid.attach( $rb, 0, $button-grid-row++, 1, 1);

    # joining a group seems to trigger the signal too, the name of the
    # grid is then not yet set. therefore register a signal after
    # attached to grid.
    $rb.register-signal( self, 'input-change-handler', 'clicked', :$row);
  }

  # set first button on
  $rb-first.set-active(True);

  $button-grid
}

#`{{
#-------------------------------------------------------------------------------
method get-value ( $button-grid --> Any ) {

  my Str $label;
  loop ( my Int $row = 0; $row < $!question.fieldlist.elems; $row++ ) {
    my Gnome::Gtk4::RadioButton $rb .= new(
      :native-object($button-grid.get-child-at( 0, $row))
    );

    if ?$rb.get-active {
      $label = $rb.get-label;
      last;
    }
  }

  $label
}
}}

#-------------------------------------------------------------------------------
method set-value ( Any:D $button-grid, $label ) {

  return unless ?$label;

  loop ( my Int $row = 0; $row < $!question.fieldlist.elems; $row++ ) {
    my Gnome::Gtk4::RadioButton() $rb = $button-grid.get-child-at( 0, $row);
    if $rb.get-label eq $label {
      # set-active() will also trigger signal
      $rb.set-active(True);
      last;
    }
  }
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $button-grid ) {
}

#-------------------------------------------------------------------------------
method input-change-handler (
  Gnome::Gtk4::RadioButton() :_native-object($radiobutton), Int() :$row
) {

  # must get the grid because the unit is a grid
  my Gnome::Gtk4::Grid() $grid = $radiobutton.get-parent;

  # store in user data without checks
  self.process-widget-input( $grid, $radiobutton.get-label, $row, :!do-check);
}
