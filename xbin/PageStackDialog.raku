#!/usr/bin/env raku

#tp:1:SheetStackDialog.raku

use v6.d;

note @*ARGS.join(', ');

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::PageStackDialog;
use QA::Types;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageStackDialog $!sheet-dialog;

  #---------
  method show-stack ( Str:D :$sheet-name ) {
    $!sheet-dialog .= new(
      :$sheet-name, :show-cancel-warning, :save-data,
      :result-handler-object(self), :result-handler-method<display-result>
    );

    $!sheet-dialog.show-sheet;
    $!sheet-dialog.clear-object;
  }

  #---------
  method display-result ( Hash $result-user-data ) {
    $!sheet-dialog.show-hash($result-user-data);
  }

  #---------
  method exit-app ( ) {
    Gnome::Gtk3::Main.new.quit;
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

    # return an array of follow up actions. show-select2 is mapped to
    # method fieldtype-action2
#    [%( :type(QAOtherUserAction), :action-key<show-select2>, :opt1<opt1>),]
    [%( :type(QAOtherUserAction), :action-key<fieldtype-action2>, :opt1<opt1>),]
  }

  method fieldtype-action2 ( Str $input, :$opt1 --> Array ) {
    note "Selected 2: $input, option: $opt1";

    # no further actions
    Array
  }

#`{{
  method extend-selectlist ( Str $input --> Array ) {
    note "Extend select list: $input";

    # no further actions
    Array
  }
}}
}

#-------------------------------------------------------------------------------
sub MAIN (
  Str $sheet-name = 'StackTest',
  Str $desktop-file = '',
  Str :$data = 'xbin/Data', Str :$sheets = 'xbin/Data/Sheets',
) {

  # modify paths for tests to come.
  given my QA::Types $qa-types {
    .data-file-type(QAYAML);
    .cfgloc-userdata($data);
    .cfgloc-sheet($sheets);
  }

  # data structure
  my EH $eh .= new;

  # set keys for check methods. keys are used in QA description
  with $qa-types .= instance {
    .set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
  #  .set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
  #  .set-action-handler( 'show-select2', $eh, 'fieldtype-action2');
    .set-action-handler( 'fieldtype-action1', $eh);
    .set-action-handler( 'fieldtype-action2', $eh);
  }

  my Gnome::Gtk3::Label $description .= new(:text(''));
  $description.set-markup(Q:to/EOLABEL/);

    Show a <b>QAStack</b> view with a few pages
    and some special questions of which one
    is a <u>user defined</u> field on the 2nd page.

    EOLABEL

  my Gnome::Gtk3::Button $dialog-button .= new(:label<QAStack>);
  $dialog-button.register-signal( $eh, 'show-stack', 'clicked', :$sheet-name);

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

  Gnome::Gtk3::Main.new.main;
}