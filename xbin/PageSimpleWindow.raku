#!/usr/bin/env raku

use v6;

use Gnome::Gtk4::Main:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::Label:api<2>;

use QA::Gui::PageSimpleWindow;
use QA::Types;
use QA::Status;

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageSimpleWindow $.qst-window;

  #---------
  method show-window ( :$app-window ) {
    with my Gnome::Gtk4::Window $window .= new {
      .set-title('questionnaire in window');
      .set-transient-for($app-window);
#      .set-size-request( );

      $!qst-window .= new(
        :qst-name<SimpleTest>, :!show-cancel-warning, :!save-data,
        :widget($window)
      );

      .show-all;

#note "window allocated: ", .get-allocation;
#      $!qst-window.resize-container;
    }
  }

  #---------
  method exit-app ( ) {
    Gnome::Gtk4::Main.new.gtk-main-quit;
  }
}

#-------------------------------------------------------------------------------
# data structure
my EH $eh .= new;

# modify some path for tests to come
given my QA::Types $qa-types {
  .data-file-type(QAJSON);
  .set-root-path('xbin/Data');
  mkdir 'xbin/Data', 0o700 unless 'xbin/Data'.IO.e;
}

my Gnome::Gtk4::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QASimpleWindow</b> view with only
  one page. Quitting is specified here to not
  display a warning and just quit.

  EOLABEL

my Gnome::Gtk4::Window $top-window .= new;

my Gnome::Gtk4::Button $dialog-button .= new(:label<QASimpleWindow>);
$dialog-button.register-signal(
  $eh, 'show-window', 'clicked', :app-window($top-window)
);

with my Gnome::Gtk4::Grid $grid .= new {
  .attach( $description, 0, 0, 1, 1);
  .attach( $dialog-button, 0, 1, 1, 1);
}

with $top-window {
  .set-title('Simple Sheet Test');
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
