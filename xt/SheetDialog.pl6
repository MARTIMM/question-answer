#!/usr/bin/env raku

use v6;
#use lib '../gnome-gobject/lib';

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Button;

use QAManager::Gui::SheetDialog;
use QAManager::Gui::Frame;
use QAManager::Gui::Value;
use QAManager::QATypes;
use QAManager::Question;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
# A user definable widget
class MyWidget does QAManager::Gui::Value {

  #---------
  method init-widget (
    QAManager::Question:D :$!question, Hash:D :$!user-data-set-part
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
    # important to initialize here because destroy of dialogs native object
    # destroyes everything on it including this objects native objects.
    # we need to rebuild it everytime the dialog is (re)run.
    my QAManager::QATypes $qa-types .= instance;
    $qa-types.set-widget-object( 'use-my-widget', MyWidget.new);

    my QAManager::Gui::SheetDialog $sheet-dialog .= new(
      :sheet-name<QAManagerSetDialog>,
      :show-cancel-warning, :!save-data
    );

    $sheet-dialog.register-signal( self, 'dialog-response', 'response');
    $sheet-dialog.show-dialog;
  }

  #---------
  method dialog-response (
    int32 $response, QAManager::Gui::SheetDialog :_widget($dialog)
  ) {
    note "dialog response: $response, ", GtkResponseType($response);

    if GtkResponseType($response) ~~ GTK_RESPONSE_OK {
      if $dialog.faulty-state {
        note 'Faulty state';
      }

      else {
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
    }
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

my QAManager::QATypes $qa-types .= instance;
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

my QAManager::QATypes $qa-types .= instance;
$qa-types.data-file-type = QAJSON;
$qa-types.cfgloc-userdata = 'xt/Data';
$qa-types.set-check-handler( 'check-exclam', $eh, 'check-char', :char<!>);


my Gnome::Gtk3::Window $top-window .= new;
$top-window.set-title('Sheet Dialog Test');
$top-window.register-signal( $eh, 'exit-app', 'destroy');
$top-window.set-size-request( 300, 1);
$top-window.window-resize( 300, 1);

my Gnome::Gtk3::Button $dialog-button .= new(:label<Show>);
$top-window.container-add($dialog-button);
$dialog-button.register-signal( $eh, 'show-dialog', 'clicked');

$top-window.show-all;

Gnome::Gtk3::Main.new.gtk-main;
