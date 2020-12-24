#!/usr/bin/env raku

use v6;
#use lib '../gnome-gobject/lib';

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;

use QA::Gui::SheetDialog;
use QA::Gui::Frame;
use QA::Gui::Value;
use QA::Types;
use QA::Question;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
# A user definable widget
class MyWidget does QA::Gui::Value {

  #---------
  method init-widget (
    QA::Question:D :$!question, Hash:D :$!user-data-set-part
  ) {

    # widget is not repeatable
    $!question.repeatable = False;

    self.initialize;
  }

  #---------
  method create-widget ( Str $widget-name, Int $row --> Any ) {

    # create a text input widget
    my Gnome::Gtk3::Button $button .= new;
    $button.set-label('0');
    $button.set-hexpand(False);
    $button.register-signal( self, 'change-label', 'clicked');

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
  method change-label ( :_widget($button) ) {
    my ( $n, $row ) = $button.get-name.split(':');
    $row .= Int;
    my Str $l = $button.get-label // '0';
    my Int $i = $l.Int + 1;
    $button.set-label("$i");
    self.process-widget-signal( $button, $row, :!do-check);
  }
}


#-------------------------------------------------------------------------------
class EH {

  method show-dialog ( ) {
    my QA::Gui::SheetDialog $sheet-dialog .= new(
      :sheet-name<DialogTest>,
      :!show-cancel-warning, :!save-data
    );

    my Int $response = $sheet-dialog.show-dialog;
    self.display-result( $response, $sheet-dialog);
  }

  method show-notebook ( ) {
    # important to initialize here because destroy of dialogs native object
    # destroyes everything on it including this objects native objects.
    # we need to rebuild it everytime the dialog is (re)run.
    my QA::Types $qa-types .= instance;
    $qa-types.set-widget-object( 'use-my-widget', MyWidget.new);

    my QA::Gui::SheetDialog $sheet-dialog .= new(
      :sheet-name<NotebookTest>,
      :show-cancel-warning, :save-data
    );

    my Int $response = $sheet-dialog.show-dialog;
    self.display-result( $response, $sheet-dialog);
  }

  method show-stack ( ) {
    my QA::Gui::SheetDialog $sheet-dialog .= new(
      :sheet-name<StackTest>,
      :show-cancel-warning, :save-data
    );

    my Int $response = $sheet-dialog.show-dialog;
    self.display-result( $response, $sheet-dialog);
  }

  method show-assistant ( ) {
    my QA::Gui::SheetDialog $sheet-dialog .= new(
      :sheet-name<AssistantTest>,
      :show-cancel-warning, :save-data
    );

#    my Int $response = $sheet-dialog.show-dialog;
#    self.display-result( $response, $sheet-dialog);
  }

  #---------
  method display-result ( Int $response, QA::Gui::SheetDialog $dialog ) {

    note "Dialog return status: ", GtkResponseType($response);
    return unless $response ~~ GTK_RESPONSE_OK;

    my $i = 0;
    sub show-hash ( Hash $h ) {
      $i++;
      for $h.keys.sort -> $k {
        if $h{$k} ~~ Hash {
          note '  ' x $i, "$k => \{";
          show-hash($h{$k});
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

    show-hash($dialog.result-user-data);
    $dialog.widget-destroy;
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
my QA::Types $qa-types .= instance;
$qa-types.data-file-type = QAYAML;
$qa-types.cfgloc-userdata = 'xbin/Data';
$qa-types.cfgloc-category = 'xbin/Data/Categories';
$qa-types.cfgloc-sheet = 'xbin/Data/Sheets';
$qa-types.set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);
$qa-types.set-action-handler( 'show-select1', $eh, 'fieldtype-action1');
$qa-types.set-action-handler(
  'show-select2', $eh, 'fieldtype-action2', :opt1<opt1>
);


my Gnome::Gtk3::Window $top-window .= new;
$top-window.set-title('Sheet Dialog Test');
$top-window.register-signal( $eh, 'exit-app', 'destroy');
$top-window.set-size-request( 300, 1);
$top-window.window-resize( 300, 1);

my Gnome::Gtk3::Grid $grid .= new;
$top-window.container-add($grid);

my Gnome::Gtk3::Button $dialog-button .= new(:label<QADialog>);
$grid.grid-attach( $dialog-button, 0, 0, 1, 1);
$dialog-button.register-signal( $eh, 'show-dialog', 'clicked');

$dialog-button .= new(:label<QANotebook>);
$grid.grid-attach( $dialog-button, 1, 0, 1, 1);
$dialog-button.register-signal( $eh, 'show-notebook', 'clicked');

$dialog-button .= new(:label<QAStack>);
$grid.grid-attach( $dialog-button, 2, 0, 1, 1);
$dialog-button.register-signal( $eh, 'show-stack', 'clicked');

$dialog-button .= new(:label<QAAssistant>);
$grid.grid-attach( $dialog-button, 3, 0, 1, 1);
$dialog-button.register-signal( $eh, 'show-assistant', 'clicked');

$top-window.show-all;

Gnome::Gtk3::Main.new.gtk-main;
