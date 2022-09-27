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
use QA::Status;

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageSimpleDialog $.qst-dialog;

  #---------
  method show-dialog ( ) {
    $!qst-dialog .= new(
      :qst-name<SimpleTest>, :!show-cancel-warning, :!save-data,
    );

    $!qst-dialog.show-qst;
    $!qst-dialog.clear-object;
  }

  #---------
  method display-result ( Hash $result-user-data ) {
    $!qst-dialog.show-hash($result-user-data);
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
  .set-root-path('xbin/Data');
  mkdir 'xbin/Data', 0o700 unless 'xbin/Data'.IO.e;
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
