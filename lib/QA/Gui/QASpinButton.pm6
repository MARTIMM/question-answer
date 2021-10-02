use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk3::SpinButton;
use Gnome::Gtk3::Adjustment;

#-------------------------------------------------------------------------------
unit class QA::Gui::QASpinButton;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
# Make attributes readable so that the roles can access them using self.question
has QA::Question $.question;
has Hash $.user-data-set-part;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part
) {
  $!question.repeatable = False;
  $!question.selectlist = [];
}

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # create a spin button input widget
  my Num $minimum = ($!question.minimum // 0).Num;
  my Gnome::Gtk3::Adjustment $adjustment .= new(
    :value($minimum),
    :lower($minimum),
    :upper($!question.maximum // 100),
    :step-increment($!question.step-incr // 1),
    :page-increment($!question.page-incr // 2),
    :page-size($!question.page-size // 10)
  );

  my Gnome::Gtk3::SpinButton $spin-button .= new(
    :$adjustment, :climb-rate($!question.climbrate // 2),
    :digits($!question.digits // 0)
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
method input-change-handler ( :_widget($spin-button), Int() :$row ) {
  self.process-widget-input(
    $spin-button, $spin-button.get-value, $row, :!do-check
  );
}
