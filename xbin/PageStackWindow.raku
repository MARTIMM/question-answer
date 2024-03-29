#!/usr/bin/env raku

#tp:1:SheetStackDialog.raku

use v6.d;

#note @*ARGS.join(', ');

#use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::Main:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::Label:api<2>;

use QA::Gui::PageStackWindow;
use QA::Types;
use QA::Status;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
class EH {
  has QA::Gui::PageStackWindow $.qst-window;

  #---------
  method show-stack ( Str:D :$qst-name ) {
    my Gnome::Gtk4::Window $window .= new;
    $window.set-title('questionnaire in window');

    $!qst-window .= new(
      :$qst-name, :show-cancel-warning, :save-data, :widget($window)
    );

    $window.show-all;
  }

  #---------
  method exit-app ( ) {
    Gnome::Gtk4::Main.new.quit;
  }

  #---------
  # TODO: a class with these methods should be loaded at runtime when
  # necessary
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
  Str $qst-name = 'StackTest',
  Str $desktop-file = '',
  Str :$data = 'xbin/Data/User', Str :$qst = 'xbin/Data/Qsts',
) {

  # modify paths for tests to come.
  given my QA::Types $qa-types {
    .data-file-type(QAYAML);
    .set-root-path('xbin/Data');
    mkdir 'xbin/Data', 0o700 unless 'xbin/Data'.IO.e;
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

  my Gnome::Gtk4::Label $description .= new(:text(''));
  $description.set-markup(Q:to/EOLABEL/);

    Show a <b>QAStack</b> view with a few pages
    and some special questions of which one
    is a <u>user defined</u> field on the 2nd page.

    EOLABEL

  my Gnome::Gtk4::Button $dialog-button .= new(:label<QAStack>);
  $dialog-button.register-signal( $eh, 'show-stack', 'clicked', :$qst-name);

  with my Gnome::Gtk4::Grid $grid .= new {
    .attach( $description, 0, 0, 1, 1);
    .attach( $dialog-button, 0, 1, 1, 1);
  }

  with my Gnome::Gtk4::Window $top-window .= new {
    .set-title('Stack Sheet Test');
    .register-signal( $eh, 'exit-app', 'destroy');
    .set-border-width(20);
    .add($grid);
    .show-all;
  }

  Gnome::Gtk4::Main.new.main;

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
}
