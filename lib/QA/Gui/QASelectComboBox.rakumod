use v6;

use Gnome::Gdk3::Events;

use Gnome::Gtk4::Entry:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::ComboBoxText:api<2>;

use QA::Types;

use QA::Gui::QAComboBox;

#-------------------------------------------------------------------------------
unit class QA::Gui::QASelectComboBox:auth<github:MARTIMM>;
also is Gnome::Gtk4::ComboBoxText;

constant \ComboBoxText = Gnome::Gtk4::ComboBoxText:api<2>;
constant \Entry = Gnome::Gtk4::Entry:api<2>;

#-------------------------------------------------------------------------------
has $!input-widget;
has $!widget-object;

# When filling in values from user data, the combobox events will fire when
# selection is changed. Use this flag to stop responding when it is not needed.
has Bool $!inhibit-combobox-events = False;

#-------------------------------------------------------------------------------
submethod new ( Bool :$use-entry = False, *%o ) {
  if $use-entry {
    self.bless( :GtkComboBoxText, :entry, :use-entry,  |%o);
  }

  else {
    self.bless( :GtkComboBoxText, :!entry, :!use-entry, |%o);
  }
}

#-------------------------------------------------------------------------------
submethod BUILD (
  :$!input-widget, :$!widget-object, Array :$select-list,
  Gnome::Gtk4::Grid :$grid, Int :current-grid-row($row-grid),
  Int :current-grid-index($row-index), Bool :$use-entry = False
) {

  if $use-entry {
    my Entry() $entry = self.get-child;
    $entry.register-signal(
      self, 'combobox-entry-handler', 'focus-out-event', :$row-grid
    );
  }

  $!widget-object.add-class( self, 'QAComboBoxText');

  for @$select-list -> $select-item {
    self.append-text($select-item);
  }

  self.set-active(0);
  self.register-signal( self, 'combobox-change', 'changed', :$row-grid);

  # Create an extra grid so that the combobox get normal height instead of
  # stretched into the height of the neighboring widget
  my Gnome::Gtk4::Grid $combo-grid .= new;
  $combo-grid.attach( self, 0, 0, 1, 1);
  $grid.attach( $combo-grid, QACatColumn, $row-index, 1, 1);
}


#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
# called when a selection changes in the $!question.selectlist combobox.
# it must adjust the selection value. no check is needed because
# input field is not changed.
method combobox-change ( Int :$row-grid --> Int ) {
#CONTROL { when CX::Warn {  note .gist; .resume; } }

note "combobox-change, $!inhibit-combobox-events, $!input-widget, $row-grid";

  unless $!inhibit-combobox-events {
    my Int $cb-select = self.get-active;
    my Str $cb-text = self.get-active-text;

    $!widget-object.process-widget-input(
      $!input-widget, $!widget-object.get-value($!input-widget),
      $row-grid, :!do-check
    );
  }

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}

#-------------------------------------------------------------------------------
method combobox-entry-handler (
  N-GdkEventFocus() $no, Gnome::Gtk4::Entry() :_native-object($entry),
  :$row-grid
  --> Int
) {
note "combobox-entry-handler, $!inhibit-combobox-events, $!input-widget, $row-grid, {self}, $entry";

  my Int $cb-select  = self.get-active;
  if $cb-select == -1 {
    my Str $cb-text = self.get-active-text;
    self.append-text($cb-text);
  }


  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}
