#!/usr/bin/env raku

use v6;
#use lib '../gnome-gobject/lib';

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::PageNotebookDialog;
use QA::Gui::Value;
use QA::Types;
use QA::Status;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
constant \PageNotebookDialog = QA::Gui::PageNotebookDialog;

#-------------------------------------------------------------------------------
# A user definable widget
class MyWidget does QA::Gui::Value {

  #---------
  method create-widget ( Int() :$row --> Any ) {

    # widget is not repeatable
    $!question.repeatable = False;

    # create a text input widget
    my Gnome::Gtk3::Button $button .= new;
    $button.set-label('0');
    $button.set-hexpand(False);
    $button.register-signal( self, 'input-change-handler', 'clicked', :$row);

    $button
  }

  #---------
  method get-value ( $button --> Any ) {
    $button.get-label;
  }

  #---------
  method set-value ( Any:D $button, $label ) {
    $button.set-label($label);
  }

  #---------
  method input-change-handler (
    Gnome::Gtk3::Button() :_native-object($button), Int() :$row
  ) {
    my Str $label = (($button.get-label // '0').Int + 1).Str;
    $button.set-label($label);
    self.process-widget-input( $button, $label, $row, :!do-check);
  }
}

#-------------------------------------------------------------------------------
class EH {
  has PageNotebookDialog $.qst-dialog;

  method show-notebook ( ) {
    # important to initialize here because destroy of dialogs native object
    # destroys everything on it including this objects native objects.
    # we need to rebuild it everytime the dialog is (re)run.
    my QA::Types $qa-types .= instance;
    $qa-types.set-widget-object( 'use-my-widget', MyWidget.new);

    $!qst-dialog .= new(
      :qst-name<NotebookTest>, :show-cancel-warning, :save-data
    );

    $!qst-dialog.show-sheet;
    $!qst-dialog.clear-object;
  }

  #---------
  method exit-app ( ) {
    Gnome::Gtk3::Main.new.gtk-main-quit;
  }

  #---------
  # check methods
  method check-char ( Str $input, :$char --> Any ) {
    "No $char allowed in string" if ?($input ~~ m/$char/)
  }

  #---------
  # action methods
  method fieldtype-action1 ( Str $input --> Array ) {
    note "Selected 1: $input";

    [%( :type(QAOtherUserAction), :action-key<show-select2>),]
  }

  method fieldtype-action2 ( Str $input, :$opt1 --> Array ) {
    note "Selected 2: $input, option: $opt1";

    [%(),]
  }
}

#-------------------------------------------------------------------------------
# data structure
my EH $eh .= new;

# get types instance and modify some path for tests to come and also some
# user methods to handle checks and actions
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata('xbin/Data');
  .cfgloc-sheet('xbin/Data/Qsts');
  .cfgloc-set('xbin/Data/Sets'); # not used - prevents creating sets.d
}

# Now we can set some more in the current instance after
# directories are created
$qa-types .= instance;
$qa-types.set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
$qa-types.set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
$qa-types.set-action-handler(
  'show-select2', $eh, 'fieldtype-action2', :opt1<opt1>
);



my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QANotebook</b> view with a few pages
  and some special questions of which one
  is a <u>user defined</u> field on the 2nd page.

  EOLABEL


my Gnome::Gtk3::Button $dialog-button .= new(:label<QANotebook>);
$dialog-button.register-signal( $eh, 'show-notebook', 'clicked');


my Gnome::Gtk3::Grid $grid .= new;
$grid.attach( $description, 0, 0, 1, 1);
$grid.attach( $dialog-button, 0, 1, 1, 1);


given my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Notebook Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
#  .set-size-request( 300, 1);
#  .window-resize( 300, 1);
  .set-border-width(20);
  .add($grid);
  .show-all;
}


Gnome::Gtk3::Main.new.gtk-main;

# show data
$eh.qst-dialog.show-hash;

my QA::Status $status .= instance;
if $status.faulty-state {
  note 'State of questionaire: incomplete and/or wrong';
  for $status.faulty-states.kv -> $name, $state {
    note "  faulty item: $name";
  }
}

else {
  note 'State of questionaire: ok';
}
