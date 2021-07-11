#!/usr/bin/env raku

use v6;
#use lib '../gnome-gobject/lib';

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::SheetNotebook;
#use QA::Gui::Frame;
#use QA::Gui::Value;
use QA::Types;
#use QA::Question;

#use Gnome::N::X;
#Gnome::N::debug(:on);


#-------------------------------------------------------------------------------
class EH {

  #---------
  method show-notebook ( ) {

    my QA::Gui::SheetNotebook $sheet-dialog .= new(
      :sheet-name<LittleNotebookTestEntry>,
      :show-cancel-warning, :save-data
    );

    my Int $response = $sheet-dialog.show-sheet;
    self.display-result( $response, $sheet-dialog);
  }

  #---------
  method display-result ( Int $response, QA::Gui::Dialog $dialog ) {

    note "Dialog return status: ", GtkResponseType($response);
    self.show-hash($dialog.result-user-data) if $response ~~ GTK_RESPONSE_OK;
    $dialog.widget-destroy unless $response ~~ GTK_RESPONSE_NONE;
  }

  #---------
  method show-hash ( Hash $h, Int :$i is copy ) {

#note "\n$h.gist()";
note ' ';
    if $i.defined {
      $i++;
    }

    else {
      note '';
      $i = 0;
    }

    for $h.keys.sort -> $k {
      if $h{$k} ~~ Hash {
        note '  ' x $i, "$k => \{";
        self.show-hash( $h{$k}, :$i);
        note '  ' x $i, '}';
      }

      elsif $h{$k} ~~ Array {
        note '  ' x $i, "$k => $h{$k}.perl()";
      }

      else {
        note '  ' x $i, "$k => $h{$k}";
      }
    }

    $i--;
  }


  #---------
  method exit-app ( ) {
    Gnome::Gtk3::Main.new.gtk-main-quit;
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
  .cfgloc-sheet('xbin/Data/Sheets');
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
$grid.grid-attach( $description, 0, 0, 1, 1);
$grid.grid-attach( $dialog-button, 0, 1, 1, 1);

given my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Notebook Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
  .set-border-width(20);
  .add($grid);
  .show-all;
}


Gnome::Gtk3::Main.new.gtk-main;
