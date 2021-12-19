#!/usr/bin/env raku
#tp:1:SheetStackDialog.raku

use v6.d;

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::SheetStackDialog;
use QA::Types;

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::SheetStack $!sheet-dialog;

  #---------
  method show-stack ( ) {
    $!sheet-dialog .= new(
      :sheet-name<StackTest>,
      :show-cancel-warning, :save-data,
      :result-handler-object(self), :result-handler-method<display-result>
    );
#note 'build done';

    $!sheet-dialog.show-sheet;
  }

  #---------
  method display-result ( Hash $result-user-data ) {
    $!sheet-dialog.show-hash($result-user-data);
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

# modify some path for tests to come Use given because $qa-types is not defined
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata('xbin/Data');
  .cfgloc-sheet('xbin/Data/Sheets');
}

# set keys for check methods. keys are used in QA description
with $qa-types .= instance {
  .set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
  .set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
  .set-action-handler( 'show-select2', $eh, 'fieldtype-action2', :opt1<opt1>);
}

my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QAStack</b> view with a few pages
  and some special questions of which one
  is a <u>user defined</u> field on the 2nd page.

  EOLABEL

my Gnome::Gtk3::Button $dialog-button .= new(:label<QAStack>);
$dialog-button.register-signal( $eh, 'show-stack', 'clicked');

with my Gnome::Gtk3::Grid $grid .= new {
  .attach( $description, 0, 0, 1, 1);
  .attach( $dialog-button, 0, 1, 1, 1);
}

with my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Stack Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
  .set-border-width(20);
  .add($grid);
  .show-all;
}

Gnome::Gtk3::Main.new.gtk-main;
