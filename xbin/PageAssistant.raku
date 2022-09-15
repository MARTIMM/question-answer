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

use QA::Gui::SheetAssistant;
use QA::Types;

#-------------------------------------------------------------------------------
class EH {

  method show-assistant ( ) {
    my QA::Gui::SheetAssistant $sheet-dialog .= new(
      :sheet-name<AssistantTest>,
      :show-cancel-warning, :save-data
    );

#    my Int $response = $sheet-dialog.show-qst;
#    self.display-result( $response, $sheet-dialog);
  }

#`{{
  #---------
  method display-result ( Int $response, QA::Gui::Dialog $dialog ) {

    note "Dialog return status: ", GtkResponseType($response);
    self.show-hash($dialog.result-user-data) if $response ~~ GTK_RESPONSE_OK;
    $dialog.widget-destroy unless $response ~~ GTK_RESPONSE_NONE;
  }

  #---------
  method show-hash ( Hash $h, Int :$i is copy ) {
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
}}

  #---------
  method exit-app ( ) {
    Gnome::Gtk3::Main.new.gtk-main-quit;
  }

#`{{
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
}}
}

#-------------------------------------------------------------------------------
# data structure
my EH $eh .= new;

#`{{
my Hash $user-data = %(
  page1 => %(
    QAManagerDialogs => %(
      set-spec => %(
        :name('my key'),
        :title('whatsemegaddy'),
        :description('longer text')
      ),
    ),
  ),
  page2 => %(
    QAManagerDialogs => %(
      entry-spec => %(
      ),
    ),
  ),
);

my QA::Types $qa-types .= instance;
$qa-types.data-file-type = QAJSON;
$qa-types.cfgloc-userdata = 'xt/Data';
$qa-types.qa-save( 'QAManagerSetDialog', $user-data, :userdata);
#$qa-types.data-file-type = QATOML;
#$qa-types.qa-save( 'QAManagerSetDialog', $user-data, :userdata);

#note $qa-types.qa-load( 'QAManagerSetDialog', :userdata);

#$qa-types.cfgloc-category;
#$qa-types.cfgloc-sheet;
#$qa-types.callback-objects;
#exit(0);
}}

# get types instance and modify some path for tests to come and also some
# user methods to handle checks and actions

given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata('xbin/Data');
  .cfgloc-sheet('xbin/Data/Sheets');
}

#`{{
$qa-types .= instance;
$qa-types.set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
$qa-types.set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
$qa-types.set-action-handler(
  'show-select2', $eh, 'fieldtype-action2', :opt1<opt1>
);
}}

given my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Assistant Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
#  .set-size-request( 300, 1);
#  .window-resize( 300, 1);
  .set-border-width(20);
}

my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show an <b>Assistant</b> view with a few pages
  and some special questions of which one
  is a <u>user defined</u> field on the 2nd page.

  EOLABEL


my Gnome::Gtk3::Button $dialog-button .= new(:label<QAAssistant>);
$dialog-button.register-signal( $eh, 'show-assistant', 'clicked');

my Gnome::Gtk3::Grid $grid .= new;
$grid.attach( $description, 0, 0, 1, 1);
$grid.attach( $dialog-button, 0, 1, 1, 1);


$top-window.add($grid);
$top-window.show-all;

Gnome::Gtk3::Main.new.gtk-main;
