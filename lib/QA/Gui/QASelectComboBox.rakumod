use v6;

use Gnome::Gdk3::Events;

use Gnome::Gtk3::Entry;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ComboBoxText;

#-------------------------------------------------------------------------------
unit class QA::Gui::QASelectComboBox:auth<github:MARTIMM>;
also is QA::Gui::Frame;

constant \ComboBoxText = Gnome::Gtk3::ComboBoxText;
constant \Entry = Gnome::Gtk3::Entry;

#-------------------------------------------------------------------------------
has ComboBoxText() $!combobox;
has Bool $!use-entry;

#-------------------------------------------------------------------------------
submethod BUILD ( Bool :$!use-entry = False ) {

  if $entry {
    # Create combobox with a Gnome::Gtk3::Entry to enter new values
    $!combobox .= new(:entry);

    my Entry() $entry = $!combobox.get-child;
    $entry.register-signal(
      self, 'combobox-entry-handler', 'focus-out-event', :$combobox,
      :$input-widget, :$row-grid
    );
  }

  else {
    # Create combobox without a Gnome::Gtk3::Entry
    $!combobox .= new;
  }

  $!widget-object.add-class( $!combobox, 'QAComboBoxText');

  for @$select-list -> $select-item {
    .append-text($select-item);
  }

  $!combobox.set-active(0);
  $!combobox.register-signal(
    self, 'combobox-change', 'changed', :$input-widget, :$row-grid
  );
}

#-------------------------------------------------------------------------------
# A selection made from $!question.select-list and repeatable is turned on
method create-combobox (
  Array $select-list, $input-widget, $grid, Int $row-grid, Int $row-index
  --> ComboBoxText
) {

#TODO create and test for an input type combobox. flag field?

  with $!combobox {
    my Entry() $entry = .get-child;
    $entry.register-signal(
      self, 'combobox-entry-handler', 'focus-out-event', :$combobox,
      :$input-widget, :$row-grid
    );

    $!widget-object.add-class( $combobox, 'QAComboBoxText');

    for @$select-list -> $select-item {
      .append-text($select-item);
    }

    .set-active(0);
    .register-signal(
      self, 'combobox-change', 'changed', :$input-widget, :$row-grid
    );
  }

  # Create an extra grid so that the combobox get normal height instead of
  # stretched into the height of the neighboring widget
  my Gnome::Gtk3::Grid $combo-grid .= new;
  $combo-grid.attach( $combobox, 0, 0, 1, 1);
  $grid.attach( $combo-grid, QACatColumn, $row-index, 1, 1);

  $combobox
}

#-------------------------------------------------------------------------------
method

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
# called when a selection changes in the $!question.selectlist combobox.
# it must adjust the selection value. no check is needed because
# input field is not changed.
method combobox-change (
  ComboBoxText() :_native-object($combobox),
  :$input-widget, Int :$row-grid --> Int
) {
note "combobox-change, $!inhibit-combobox-events, $input-widget, $row-grid";

  unless $!inhibit-combobox-events {
    my Int $cb-select = $combobox.get-active;
    my Str $cb-text = $combobox.get-active-text;

    $!widget-object.process-widget-input(
      $input-widget, $!widget-object.get-value($input-widget),
      $row-grid, :!do-check
    );
  }

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}

#-------------------------------------------------------------------------------
method combobox-entry-handler (
  N-GdkEventFocus() $no, Gnome::Gtk3::Entry() :_native-object($entry),
  :$combobox, :$input-widget, :$row-grid
  --> Int
) {
note "combobox-entry-handler, $!inhibit-combobox-events, $input-widget, $row-grid, $combobox, $entry";

  my Int $cb-select  = $combobox.get-active;
  if $cb-select == -1 {
    my Str $cb-text = $combobox.get-active-text;
    $combobox.append-text($cb-text);
  }


  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}
