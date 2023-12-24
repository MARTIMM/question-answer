#!/usr/bin/env raku

use v6;
#use lib '../gnome-gobject/lib';

#use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::Main:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::Label:api<2>;

use QA::Gui::PageNotebookWindow;
#use QA::Gui::Value;
use QA::Types;
use QA::Status;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
constant \PageNotebookWindow = QA::Gui::PageNotebookWindow;

#-------------------------------------------------------------------------------
# A user definable widget
class MyWidget does QA::Gui::Value {

  #---------
  method create-widget ( Int() :$row --> Any ) {

    # widget is not repeatable
    $!question.repeatable = False;

    # create a text input widget
    my Gnome::Gtk4::Button $button .= new;
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
    Gnome::Gtk4::Button() :_native-object($button), Int() :$row
  ) {
    my Str $label = (($button.get-label // '0').Int + 1).Str;
    $button.set-label($label);
    self.process-widget-input( $button, $label, $row, :!do-check);
  }
}

#-------------------------------------------------------------------------------
class EH {
  has PageNotebookWindow $.qst-window;

  method show-notebook ( Str:D :$qst-name ) {
    my QA::Types $qa-types .= instance;
    $qa-types.set-user-input-widget( 'use-my-widget', MyWidget.new);

    my Gnome::Gtk4::Window $window .= new;
    $window.set-title('questionnaire in window');

    $!qst-window .= new(
      :$qst-name, :show-cancel-warning, :save-data, :widget($window)
    );

    $window.show-all;
  }

  #---------
  method exit-app ( ) {
    Gnome::Gtk4::Main.new.gtk-main-quit;
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
  .set-root-path('xbin/Data');
  mkdir 'xbin/Data', 0o700 unless 'xbin/Data'.IO.e;
}

# Now we can set some more in the current instance after
# directories are created
$qa-types .= instance;
$qa-types.set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
$qa-types.set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
$qa-types.set-action-handler(
  'show-select2', $eh, 'fieldtype-action2', :opt1<opt1>
);

my Gnome::Gtk4::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QANotebook</b> view with a few pages
  and some special questions of which one
  is a <u>user defined</u> field on the 2nd page.

  EOLABEL

my Gnome::Gtk4::Button $dialog-button .= new(:label<QANotebook>);
$dialog-button.register-signal(
  $eh, 'show-notebook', 'clicked', :qst-name<NotebookTest>
);

with my Gnome::Gtk4::Grid $grid .= new {
  .attach( $description, 0, 0, 1, 1);
  .attach( $dialog-button, 0, 1, 1, 1);
}

with my Gnome::Gtk4::Window $top-window .= new {
  .set-title('Notebook Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
  .set-border-width(20);
  .add($grid);
  .show-all;
}

Gnome::Gtk4::Main.new.gtk-main;

# show data
$eh.qst-window.show-hash;

my QA::Status $status .= instance;
if $status.faulty-state {
  note 'State of questionnaire: incomplete and/or wrong';
  for $status.faulty-states.kv -> $name, $state {
    note "  faulty item: $name";
  }
}

else {
  note 'State of questionnaire: ok';
}
