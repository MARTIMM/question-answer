#!/usr/bin/env raku

use v6.d;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Label;

use QA::Gui::PageSimpleWindow;
use QA::Types;
use QA::Status;

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageSimpleWindow $.qst-window;

  #---------
  method show-window ( :$app-window ) {
    my Gnome::Gtk3::Window $window .= new;
    $window.set-title('questionaire in window');
    $window.set-transient-for($app-window);

    $!qst-window .= new(
      :qst-name<SimpleTest>, :!show-cancel-warning, :!save-data,
      :widget($window)
    );

    $window.show-all;
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
  .set-root-path('xbin/Data');
  mkdir 'xbin/Data', 0o700 unless 'xbin/Data'.IO.e;
}

my Gnome::Gtk3::Label $description .= new(:text(''));
$description.set-markup(Q:to/EOLABEL/);

  Show a <b>QASimpleWindow</b> view with only
  one page. Quitting is specified here to not
  display a warning and just quit.

  EOLABEL

my Gnome::Gtk3::Window $top-window .= new;

my Gnome::Gtk3::Button $dialog-button .= new(:label<QASimpleWindow>);
$dialog-button.register-signal(
  $eh, 'show-window', 'clicked', :app-window($top-window)
);

with my Gnome::Gtk3::Grid $grid .= new {
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

Gnome::Gtk3::Main.new.gtk-main;

# show data
$eh.qst-window.show-hash;

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
