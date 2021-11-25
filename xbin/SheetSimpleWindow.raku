#!/usr/bin/env raku

use v6.d;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::SheetSimpleWindow;
use QA::Types;

#-------------------------------------------------------------------------------
class EH {
  method show-window ( :$app-window ) {
    with my Gnome::Gtk3::Window $window .= new {
      .set-title('sheet in window');
      .set-transient-for($app-window);
    }

    my QA::Gui::SheetSimpleWindow $sheet-window .= new(
      :sheet-name<SimpleTest>,
      :!show-cancel-warning, :!save-data
      :widget($window)
    );
#CONTROL { when CX::Warn {  note .gist; .resume; } }

    my Int $response = $sheet-window.show-sheet;
    self.display-result( $response, $sheet-window);
  }

#`{{
  method show-dialog ( ) {
    my QA::Gui::SheetSimpleDialog $sheet-window .= new(
      :sheet-name<SimpleTest>,
      :!show-cancel-warning, :!save-data
    );
#CONTROL { when CX::Warn {  note .gist; .resume; } }

    my Int $response = $sheet-window.show-sheet;
    self.display-result( $response, $sheet-window);
  }
}}

  #---------
  method display-result ( Int $response, QA::Gui::SheetSimpleWindow $window ) {

#    note "Dialog return status: ", GtkResponseType($response) // 'no response';
    self.show-hash($window.result-user-data); # if $response ~~ GTK_RESPONSE_OK;
#    $window.widget-destroy; # unless $response ~~ GTK_RESPONSE_NONE;
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

  #---------
  method exit-app ( ) {
    Gnome::Gtk3::Main.new.gtk-main-quit;
  }
}

#-------------------------------------------------------------------------------
# data structure
my EH $eh .= new;

# modify some path for tests to come
given my QA::Types $qa-types {
  .data-file-type(QAJSON);
  .cfgloc-userdata('xbin/Data');
  .cfgloc-sheet('xbin/Data/Sheets');
}

given my Gnome::Gtk3::Window $top-window .= new {
  .set-title('Simple Sheet Test');
  .register-signal( $eh, 'exit-app', 'destroy');
  .set-border-width(20);
}

my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QASimpleWindow</b> view with only
  one page. Quitting is specified here to not
  display a warning and just quit.

  EOLABEL

my Gnome::Gtk3::Button $dialog-button .= new(:label<QASimpleWindow>);
$dialog-button.register-signal(
  $eh, 'show-window', 'clicked', :app-window($top-window)
);

my Gnome::Gtk3::Grid $grid .= new;
$grid.attach( $description, 0, 0, 1, 1);
$grid.attach( $dialog-button, 0, 1, 1, 1);

$top-window.add($grid);
$top-window.show-all;

Gnome::Gtk3::Main.new.gtk-main;
