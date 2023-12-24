use v6;

use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;

use QA::Types;
use QA::Set;
use QA::Question;

use QA::Gui::QALabel;
use QA::Gui::InputWidget;

#use QA::Gui::QAEntry;
#use QA::Gui::QAFileChooser;
#use QA::Gui::QAImage;

#use QA::Gui::QACheckButton;
#use QA::Gui::QAComboBox;
#use QA::Gui::QARadioButton;
#use QA::Gui::QASpinButton;
#use QA::Gui::QASwitch;
#use QA::Gui::QATextView;

#-------------------------------------------------------------------------------
unit class QA::Gui::Question:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
# Defined by calling method to show which row in the grid can be occupied
has Gnome::Gtk4::Grid $!question-grid;
has Int $!grid-row;

has Hash $!user-data-set-part;
has QA::Question $!question;
has QA::Gui::InputWidget $!widget-object;

has Hash $.pages;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part,
  Gnome::Gtk4::Grid:D :$!question-grid, Int:D :row($!grid-row),
  Hash :$!pages
) {
  die 'Missing name field in question data' unless ? $!question.name;

  self!display-question;
}

#-------------------------------------------------------------------------------
method !display-question ( ) {

  # on each row in the provided grid, a label with the question comes on the
  # left. Then, in the middle, an optional '*' when the user is required to
  # provide an answer. And finally on the right, an input widget.

  # description text
  my Str $text = $!question.description // $!question.title ~ ':';
  $!question-grid.attach(
    QA::Gui::QALabel.new(:$text), QAQuestion, $!grid-row, 1, 1
  );

  # mark required fields with a bold star
  $text = $!question.required ?? ' <b>*</b> ' !! ' ';
  with my $r-label = Gnome::Gtk4::Label.new(:$text) {
    .set-use-markup(True);
    .set-valign(GTK_ALIGN_START);
    .set-margin-top(6);

    Gnome::Gtk4::StyleContext.new(
      :native-object(.get-style-context)
    ).add-class('QARequiredLabel');
  }
  $!question-grid.attach( $r-label, QARequired, $!grid-row, 1, 1);

  # input widget object
  $!widget-object .= new(
    :$!question, :$!user-data-set-part, :gui-question(self)
  );
  $!question-grid.attach(
    $!widget-object, QAAnswer, $!grid-row, 1, 1
  ) if $!widget-object.defined;
}

#-------------------------------------------------------------------------------
method query-state ( --> Bool ) {

  my Bool $state;
note "$?LINE, query state: $!widget-object.raku()";

  # not all widgets are implemented
  if $!widget-object.defined {
    $state = $!widget-object.faulty-state;
note "$?LINE, query state: $state";
  }

  else {
    $state = False;
note "$?LINE, query state: $state";
  }

  $state
}







=finish

#-------------------------------------------------------------------------------
method !scale-field (
  Int $set-row, QA::Question $question
) {

  # user data is stored as a hash to make the check more easily
#  my Array $v = $!user-data{$set.name}{$question.name} // [];
#  my Hash $reversed-v = $v.kv.reverse.hash;

  my Gnome::Gtk4::Scale $w .= new(
    :orientation(GTK_ORIENTATION_HORIZONTAL),
    :min($question.minimum // 0e0), :max($question.maximum // 1e2),
    :step($question.step // 1e0)
  );

  #    $w.set-active($reversed-v{$vname}:exists);
  $w.set-name($question.name);
  $w.set-margin-top(3);
  $w.set-draw-value(True);
  $w.set-digits(2);
  $w.set-value($question.default // $question.minimum // 0e0);
  $w.set-tooltip-text($question.tooltip) if ?$question.tooltip;
  $!question-grid.attach( $w, 2, $set-row, 1, 1);

#  $!main-handler.add-widget( $g, $!invoice-title, $set, $question);
}
