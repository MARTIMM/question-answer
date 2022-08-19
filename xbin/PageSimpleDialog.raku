#!/usr/bin/env raku
#tp:1:SheetSimpleDialog.raku

use v6.d;

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::PageSimpleDialog;
use QA::Types;

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageSimpleDialog $!sheet-dialog;

  #---------
  method show-dialog ( ) {
    $!sheet-dialog .= new(
      :sheet-name<SimpleTest>,
      :!show-cancel-warning, :!save-data,
      :result-handler-object(self), :result-handler-method<display-result>
    );

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
}

#-------------------------------------------------------------------------------
# data structure
my EH $eh .= new;

# modify some path for tests to come. Use given because $qa-types is not defined
given my QA::Types $qa-types {
  .data-file-type(QAJSON);
  .cfgloc-userdata('xbin/Data');
  .cfgloc-sheet('xbin/Data/Sheets');
#  note 'dirs ', .list-dirs;
#  note 'sheets: ', .qa-list(:sheet);
#  note 'sets: ', .qa-list(:set);
#  note 'data: ', .qa-list(:userdata);
}

my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QASimpleDialog</b> view with only
  one page. Quitting is specified here to not
  display a warning and just quit.

  EOLABEL

my Gnome::Gtk3::Button $dialog-button .= new(:label<QASimpleDialog>);
$dialog-button.register-signal( $eh, 'show-dialog', 'clicked');

with my Gnome::Gtk3::Grid $grid .= new {
  .attach( $description, 0, 0, 1, 1);
  .attach( $dialog-button, 0, 1, 1, 1);
}

with my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Simple Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
  .set-border-width(20);
  .add($grid);
  .show-all;
}

Gnome::Gtk3::Main.new.gtk-main;
