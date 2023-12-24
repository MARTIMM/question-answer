use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk4::SpinButton:api<2>;
use Gnome::Gtk4::Adjustment:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::QASpinButton;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # reset constraints when used wrong
  $!question.repeatable = False;
  $!question.selectlist = [];

  # create a spin button input widget
  my Num $minimum = ($!question.options<minimum> // 0).Num;
  my Gnome::Gtk4::Adjustment $adjustment .= new(
    :value($minimum),
    :lower($minimum),
    :upper($!question.options<maximum> // 100),
    :step-increment($!question.options<step-incr> // 1),
    :page-increment($!question.options<page-incr> // 2),
    :page-size($!question.options<page-size> // 10)
  );

  my Gnome::Gtk4::SpinButton $spin-button .= new(
    :$adjustment, :climb-rate($!question.options<climbrate> // 1.5e0),
    :digits($!question.options<digits> // 0)
  );

  $spin-button.set-hexpand(False);
  $spin-button.register-signal(
    self, 'input-change-handler', 'value-changed', :$row
  );
  self.add-class( $spin-button, 'QASpinButton');

  $spin-button
}

#`{{
#-------------------------------------------------------------------------------
method get-value ( $spin-button --> Any ) {
  $spin-button.get-value;
}
}}

#-------------------------------------------------------------------------------
method set-value ( Any:D $spin-button, $value ) {
  $spin-button.set-value($value);
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $spin-button ) {
}

#-------------------------------------------------------------------------------
method input-change-handler (
  Gnome::Gtk4::SpinButton() :_native-object($spin-button), Int() :$row
) {
  self.process-widget-input(
    $spin-button, $spin-button.get-value, $row, :!do-check
  );
}
