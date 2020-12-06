use v6;

#use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Frame;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Separator;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Label;

use QAManager::Category;
use QAManager::Set;
use QAManager::Question;
use QAManager::Gui::Question;
use QAManager::Gui::Frame;
use QAManager::Gui::Dialog;

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

unit class QAManager::Gui::Set:auth<github:MARTIMM>;
#also is QAManager::Gui::Dialog;

#-------------------------------------------------------------------------------
has Hash $!user-data-set-part;
has QAManager::Set $!set;
has Array[QAManager::Gui::Question] $!questions;

#-------------------------------------------------------------------------------
# must repeat this new call because it won't call the one of
# QAManager::Gui::SetDemoDialog
#submethod new ( |c ) {
#  self.bless( :GtkDialog, |c);
#}

#-------------------------------------------------------------------------------
# Display a set on a given grid at given row
submethod BUILD (
  Gnome::Gtk3::Grid :$grid, Int:D :$grid-row,
  Str:D :$category-name, Str:D :$set-name, Hash:D :$!user-data-set-part
) {

  # get the set from cat and set names
  $!set = QAManager::Category.new(:$category-name).get-set($set-name);

  # create a frame with title
  my QAManager::Gui::Frame $set-frame .= new(:label($!set.title));
  $grid.grid-attach( $set-frame, 0, $grid-row, 1, 1);

  # the grid is for displaying the input fields and are
  # strechable horizontally
  my Gnome::Gtk3::Grid $question-grid .= new;
  $question-grid.set-border-width(5);
  #$question-grid.set-row-spacing(5);
  $question-grid.widget-set-hexpand(True);
  $set-frame.container-add($question-grid);

  # place set description at the top of the grid
  my Gnome::Gtk3::Label $description .= new(:text($!set.description));
  $description.set-line-wrap(True);
  #$description.set-max-width-chars(60);
  $description.set-justify(GTK_JUSTIFY_FILL);
  $description.widget-set-halign(GTK_ALIGN_START);
  $description.widget-set-margin-bottom(3);
  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object($description.get-style-context)
  );
  $context.add-class('descriptionText');

  my Int $question-grid-row = 0;
  $question-grid.grid-attach( $description, 0, $question-grid-row++, 3, 1);

  # a separator made a bit shorter on the sides
  my Gnome::Gtk3::Separator $sep .= new(
    :orientation(GTK_ORIENTATION_HORIZONTAL)
  );
  $sep.widget-set-margin-bottom(3);
  $sep.set-sensitive(False);
  $sep.set-margin-start(10);
  $sep.set-margin-end(10);
  $question-grid.grid-attach( $sep, 0, $question-grid-row++, 3, 1);

  # show set with user data if any on subsequent rows counting from 2
  my $c := $!set.clone;
  for $c -> QAManager::Question $question {
    my QAManager::Gui::Question $gui-q .= new(
      :$question, :$question-grid, :row($question-grid-row), :$!user-data-set-part
    );
    $!questions.push: $gui-q;
    $question-grid-row++;
  }
}

#-------------------------------------------------------------------------------
method query-state ( --> Bool ) {

  my Bool $faulty-state = False;
  for @$!questions -> $question {

    # this question is not ok when True
    if $question.query-state {
      $faulty-state = True;
      last;
    }
  }

  $faulty-state
}
