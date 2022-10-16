use v6;

#use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Frame;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Separator;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Label;

use QA::Gui::Question;
use QA::Gui::Frame;
use QA::Gui::Dialog;

use QA::Set;
use QA::Question;

#-------------------------------------------------------------------------------
=begin pod
Purpose of this part is to display a set of questions.
The format is roughly;
  parent grid
    ...
    set frame with title
      set grid
        description
        question grid
          label entry
          ...

    ...

  The questions are placed in a grid.
=end pod

unit class QA::Gui::Set:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
has Hash $!user-data-set-part;
#has Hash $!pages;
has Hash $.questions = %();

#-------------------------------------------------------------------------------
# Display a set on a given grid at given row
submethod BUILD (
  Gnome::Gtk3::Grid :$grid, Int:D :$grid-row,
  QA::Set :$set, Hash:D :$!user-data-set-part, Hash :$pages
) {

  # place set description at the top of the grid
  with my Gnome::Gtk3::Label $description .= new(:text($set.description)) {
    .set-line-wrap(True);
    #.set-max-width-chars(60);
    .set-justify(GTK_JUSTIFY_FILL);
    .widget-set-halign(GTK_ALIGN_START);
    .widget-set-margin-bottom(3);
    my Gnome::Gtk3::StyleContext() $context = .get-style-context;
    $context.add-class('descriptionText');
  }

  # a separator made a bit shorter on the sides
  with my Gnome::Gtk3::Separator $sep .= new(
      :orientation(GTK_ORIENTATION_HORIZONTAL)
    ) {
    .widget-set-margin-bottom(3);
    .set-sensitive(False);
    .set-margin-start(10);
    .set-margin-end(10);
  }

  # the grid is for displaying the input fields and are strechable horizontally.
  # Add the description and separator to the grid
  my Int $question-grid-row = 0;
  with my Gnome::Gtk3::Grid $question-grid .= new {
    .set-border-width(5);
    #.set-row-spacing(5);
    .set-hexpand(True);
    .attach( $description, 0, $question-grid-row++, 3, 1);
    .attach( $sep, 0, $question-grid-row++, 3, 1);
  }

  # create a frame with title and add grid to it
  with my QA::Gui::Frame $set-frame .= new(:label($set.title)) {
    .add($question-grid);
    $grid.attach( $set-frame, 0, $grid-row, 1, 1);
  }

  # show set with user data if any on subsequent rows counting from 2
  my $c := $set.clone;
  for $c -> QA::Question $question {
#note 'Question: ', $question.name;
    my QA::Gui::Question $gui-q .= new(
      :$question, :$question-grid, :row($question-grid-row),
      :$!user-data-set-part, :$pages
    );
    $!questions{$question.name} = $gui-q;
    $question-grid-row++;
  }
}

#-------------------------------------------------------------------------------
method query-state ( --> Bool ) {

  my Bool $faulty-state = False;
  for $!questions.kv -> $k, $question {

    # this question is not ok when True
    if $question.query-state {
      $faulty-state = True;
      last;
    }
  }

  $faulty-state
}
