use v6;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::ToolButton;
use Gnome::Gtk3::Image;

use QA::Types;
use QA::Question;

use QA::Gui::Frame;
use QA::Gui::QAEntry;
use QA::Gui::QAFileChooser;
use QA::Gui::QAImage;
use QA::Gui::QACheckButton;
use QA::Gui::QAComboBox;
use QA::Gui::QARadioButton;
use QA::Gui::QASpinButton;
use QA::Gui::QASwitch;
use QA::Gui::QATextView;

#-------------------------------------------------------------------------------
unit class QA::Gui::InputWidget:auth<github:MARTIMM>:ver<0.1.0>;
also is QA::Gui::Frame;

#-------------------------------------------------------------------------------
# Array of question parameters
has QA::Question $!question;

# Location in larger Hash, a location for the answer on this question
has Hash $!user-data-set-part;

# The place to hold the widget object
has $!widget-object;

# Grid rows holding the real input widgets
has Array $!grid-row-data;
has Array $!grid-access-index;

# The grid which displays the input widgets and other sub widgets
has Gnome::Gtk3::Grid $!grid;

# state of the input widgets held in the $!grid-row-data
has Bool $.faulty-state = False;

# When filling in values from user data, the combobox events will fire when
# selection is changed. Use this flag to stop responding when it is not needed.
has Bool $!inhibit-combobox-events = False;

#-------------------------------------------------------------------------------
submethod BUILD ( QA::Question:D :$!question, Hash:D :$!user-data-set-part ) {
  $!grid-row-data = [];
  $!grid-access-index = [];
  $!grid .= new;

  # place the grid in frame
  self.add($!grid);

  # set the name of this Frame to the widgets name
  self.set-name($!question.name);

  # make frame invisible if input is not repeatable
  if not $!question.repeatable {
    self.set-shadow-type(GTK_SHADOW_NONE);
    self.set-hexpand(True);
  }

  if $!question.fieldtype eq QAUserWidget {
    # If this is a user widget, the widget object is already created.
    self!create-user-widget-object;
  }

  else {
    # Otherwise create the widget object
    self!create-widget-object;
  }

  if ? $!widget-object {
    $!inhibit-combobox-events = True;

    # Add at least one row if widget object is valid
    self.append-grid-row;

    # And set values from user data.
    self!apply-values;
    $!inhibit-combobox-events = False;
  }

  $!faulty-state = False;
}

#-------------------------------------------------------------------------------
method !create-widget-object ( ) {
  my Str $module-name = 'QA::Gui::' ~ $!question.fieldtype.Str;
  if (my $m = ::($module-name)).^lookup('set-value') ~~ Method {
    $!widget-object = ::($module-name).new(
      :$!question, :$!user-data-set-part, :input-widget(self)
    );
  }

  else {
    # handle failure
    $m.Bool;
    note "fail to use  $module-name";
  }
}

#-------------------------------------------------------------------------------
method !create-user-widget-object ( ) {

  # Get the object from the questions userwidget field and get the object,
  # then call .init-widget() if the method is defined.
  my QA::Types $qa-types .= instance;
  $!widget-object = $qa-types.get-widget-object($!question.userwidget);
  if ?$!widget-object and $!widget-object.^lookup('init-widget') ~~ Method {
    $!widget-object.init-widget( :$!question, :$!user-data-set-part);
  }

  else {
    note "failed to use QAUserWidget, $!question.userwidget().init-widget\()";
  }
}

#-------------------------------------------------------------------------------
method append-grid-row ( --> List ) {
  my Int $current-grid-row = $!grid-row-data.elems;
  my Int $current-grid-index = $!grid-access-index.elems;
  $!grid-access-index[$current-grid-index] = $current-grid-row;

note "append-grid-row, nrows: $current-grid-row, $current-grid-index, $!grid-access-index.raku()";

  given my $input-widget = $!widget-object.create-widget(
    :row($current-grid-index)
  ) {
    my Str $tooltip = $!question.tooltip;
    .set-tooltip-text($tooltip) if ?$tooltip;
    .set-name($!question.name);
    .set-hexpand(True);
  }

  $!grid-row-data[$current-grid-row] = [];
  $!grid-row-data[$current-grid-row][QAInputColumn] = $input-widget;

  $!grid.attach( $input-widget, QAInputColumn, $current-grid-index, 1, 1);

  if $!question.repeatable {
    # create comboboxes on the left when selectlist is a non-empty Array
    my Array $select-list = $!question.selectlist // [];
    if $select-list.elems {
      my Gnome::Gtk3::ComboBoxText $cbt = self!create-combobox(
        $select-list, $input-widget, $current-grid-row, $current-grid-index
      );
      $!grid.attach( $cbt, QACatColumn, $current-grid-index, 1, 1);
      $!grid-row-data[$current-grid-row][QACatColumn] = $cbt;
    }

    my Gnome::Gtk3::ToolButton $tb;
    $tb = self!create-toolbutton( $current-grid-row, $current-grid-index, :add);
    $!grid.attach( $tb, QAToolButtonAddColumn, $current-grid-index, 1, 1);
    $!grid-row-data[$current-grid-row][QAToolButtonAddColumn] = $tb;

    $tb = self!create-toolbutton(
      $current-grid-row, $current-grid-index, :!add
    );
    $!grid.attach( $tb, QAToolButtonDelColumn, $current-grid-index, 1, 1);
    $!grid-row-data[$current-grid-row][QAToolButtonDelColumn] = $tb;
  }

  $!grid.show-all;

  self.hide-tb-add if $!question.repeatable;

#  for ^$!grid-row-data.elems -> $row {
#    last if $row == $!grid-row-data.elems - 1;
#    $!grid-row-data[$row][QAToolButtonAddColumn].hide;
#  }

  ( $input-widget, $current-grid-row, $current-grid-index)
}

#-------------------------------------------------------------------------------
method !create-toolbutton (
  Int $row-grid, Int $row-index, Bool :$add = True
  --> Gnome::Gtk3::ToolButton
) {

  my Gnome::Gtk3::Image $image .= new;
  my Str ( $tb-name, $tb-handler);

  if $add {
    $image.set-from-icon-name( 'list-add', GTK_ICON_SIZE_BUTTON);
    $tb-name = 'tb-add';
    $tb-handler = 'add-row';
  }

  else {
    $image.set-from-icon-name( 'list-remove', GTK_ICON_SIZE_BUTTON);
    $tb-name = 'tb-del';
    $tb-handler = 'del-row';
  }

  given my Gnome::Gtk3::ToolButton $tb .= new(:icon($image)) {
    .set-name($tb-name);
    .register-signal( self, $tb-handler, 'clicked', :$row-index);
    .register-signal( self, 'hide-tb-add', 'show')
;#      if $tb-name eq 'tb-add';
  }

  $!widget-object.add-class( $tb, 'QAToolButtonRowControl');

  $tb
}

#-------------------------------------------------------------------------------
# A selection made from $!question.select-list and repeatable is turned on
method !create-combobox (
  Array $select-list, $input-widget, Int $row-grid, Int $row-index
  --> Gnome::Gtk3::ComboBoxText
) {
  my Gnome::Gtk3::ComboBoxText $cbt .= new;
  for @$select-list -> $select-item {
    $cbt.append-text($select-item);
  }

  $cbt.register-signal(
    self, 'combobox-change', 'changed', :$input-widget, :$row-grid
  );

  $!widget-object.add-class( $cbt, 'QAComboBoxText');
  $cbt.set-active(0);
  $cbt
}

#-------------------------------------------------------------------------------
method !apply-values ( ) {

CONTROL { when CX::Warn {  note .gist; .resume; } }

  if $!question.repeatable {
#note 'repeated values: ', ($!widget-object.^name, $!user-data-set-part{$!question.name}).join(', ');

    # Make sure the input values is an Array, if not, initialize and return.
    my $values = $!user-data-set-part{$!question.name};
    if !$values or $values !~~ Array {
      $!user-data-set-part{$!question.name} = [];
      return;
    }


    # Loop through the values to set the input widgets
    my Int $i = 0;
    while $i < $values.elems {
      # Skip empty/undefined values
      unless ?$values[$i] {
        $values.splice( $i, 1);
        next;
      }

      # First row is always created. When more than 1 value, create more rows
      self.append-grid-row if $i > 0;

      my $input-widget = $!grid-row-data[$i][QAInputColumn];
      my $value;
      if ? $!question.selectlist {
#note "apply: $i, $values[$i].raku(), $!question.selectlist.raku()";
        my ( $select-item, $select-input) = $values[$i].kv;

        $value = $select-input;

        my Int $value-index =
          $!question.selectlist.first( $select-item, :k) // 0;

        my Gnome::Gtk3::ComboBoxText $cbt = $!grid-row-data[$i][QACatColumn];
#        $cbt = $!grid.get-child-at-rk( QACatColumn, $i);
        $cbt.set-active($value-index);
      }

      else {
#note "apply: $i, $values[$i]";
        $value = $values[$i];
      }

      $!widget-object.set-value( $input-widget, $value);
      $!widget-object.check-widget-value( $input-widget, $value, :row($i));
      $i++;
    }

    # Restore to remove any undefined or empty values
    $!user-data-set-part{$!question.name} = $values;
  }

  else {
#note "single value: $!question.name(), $!widget-object.^name, $!user-data-set-part{$!question.name}.raku()";

    my $value = $!user-data-set-part{$!question.name};
    if ?$value {
      my $input-widget = $!grid-row-data[0][QAInputColumn];
      $!widget-object.set-value( $input-widget, $value);
      $!widget-object.check-widget-value( $input-widget, $value);
    }
  }
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
# called when a selection changes in the $!question.selectlist combobox.
# it must adjust the selection value. no check is needed because
# input field is not changed.
method combobox-change (
  :_widget($combobox), :$input-widget, Int :$row-grid --> Int
) {
  unless $!inhibit-combobox-events {
#note "cbx iw: $row-grid, ", $input-widget.^name;
#note 'cbx 0: ', $combobox.get-active;
#note 'cbx 1: ', $!question.selectlist[$combobox.get-active];
#note 'cbx 2: ', $!widget-object.get-value($input-widget);
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
method add-row (
#  Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id, Int :$row-index
) {
#note "add row, name: $tb.get-name()";
#`{{
#Gnome::N::debug(:on);
  # modify this buttons icon
  my Gnome::Gtk3::Image $image .= new;
  $image.set-from-icon-name( 'list-remove', GTK_ICON_SIZE_BUTTON);
  $tb.set-icon-widget($image);

  # and signal handler
  $tb.handler-disconnect($_handler-id);
  $tb.register-signal( self, 'delete-row', 'clicked');

  # create a new row
  self!create-input-row($!input-widgets.elems);
  $!user-data-set-part{$!widget-name}.push('');
#  note 'add nrows: ', $!input-widgets.elems;
}}

  self.append-grid-row
#  $tb.hide;

#`{{
  my $next-row = $!grid-row-data.elems;

  my Gnome::Gtk3::ToolButton $tb2;
  $tb2 = self!create-toolbutton( $next-row, :add);
  $!grid.attach( $tb2, QAToolButtonAddColumn, $next-row, 1, 1);
  $tb2 = self!create-toolbutton($next-row, :!add);
  $!grid.attach( $tb2, QAToolButtonDelColumn, $next-row, 1, 1);
}}

}

#-------------------------------------------------------------------------------
#TODO deleting a row will not shift the row number given to the event handlers
method del-row (
  Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id, Int :$row-index
) {

#  my Bool $is-last-row =
#    $!grid-row-data[$row-grid][QAToolButtonAddColumn].get-visible;
  my Int $row-grid = $!grid-access-index[$row-index];
note "delete row: $row-index, $row-grid, $!grid-access-index.elems(), $!grid-row-data.elems()";

#  $!grid-row-data[$row-grid][QAToolButtonAddColumn].hide;

  # remove all widgets from this row except the last one
  if $!grid-row-data.elems() > 1 {
    $!grid-row-data[$row-grid][QAInputColumn].destroy;
    $!grid-row-data[$row-grid][QAToolButtonAddColumn].destroy;
    $!grid-row-data[$row-grid][QAToolButtonDelColumn].destroy;
    $!grid-row-data[$row-grid][QACatColumn].destroy if $!question.selectlist.defined;
    $!grid-row-data.splice( $row-grid, 1);

note "indices 0: $!grid-access-index.raku()";
    for ($row-index..^$!grid-access-index.elems) -> $index {
      $!grid-access-index[$index]--;
    }
note "indices 1: $!grid-access-index.raku()";
  }

  else {
#note 'Clear ', $!grid-row-data[$row-grid][QAInputColumn].^name, ', ', $!widget-object.^name;
    $!widget-object.clear-value($!grid-row-data[$row-grid][QAInputColumn])
      if $!widget-object.^can('clear-value') and
         ? $!grid-row-data[$row-grid][QAInputColumn];

    #$!grid-row-data[$row-grid][QAInputColumn].clear-value;
  }

  # cut out the data of this row
  my $array := $!user-data-set-part{$!question.name};
  $array.splice( $row-grid, 1) if ?$array;

  self.hide-tb-add;


#`{{
  my ( $x, $row ) = $tb.get-name.split(':');
  $row .= Int;
#note "del nr: $row, $!input-widgets.elems()";

  # all toolbuttons below this one must change its name
  loop ( my Int $r = $row.Int + 1; $r < $!input-widgets.elems; $r++ ) {
    my Gnome::Gtk3::ToolButton $tbn .= new(
      :native-object($!grid.get-child-at( QAButtonColumn, $r))
    );
    my ( $x, $row) = $tbn.get-name.split(':');
#print "rename $row of $tbn.get-name() to ";
    $tbn.set-name("tb:{$row.Int - 1}");
#note $tbn.get-name;
  }

  # delete a row from grid, an item from the widget and user data array
  $!grid.remove-row($row);
#note "A: $row, $!input-widgets.elems(), $!input-widgets.gist()";
  $!input-widgets.splice( $row, 1);
#note "U: $row, $!user-data-set-part.elems(), $!user-data-set-part.gist()";
  $!user-data-set-part{$!widget-name}.splice( $row, 1);

  # rename input widgets
  $row = 0;
  for @$!input-widgets -> $iw {
    $iw.set-name("$!widget-name:$row");
    $row++;
  }
}}
}

#-------------------------------------------------------------------------------
# Called from .append-grid-row() or as a callback from the 'show' event
# when .show-all() is called.
method hide-tb-add ( ) {
  my Int $nrows = $!grid-row-data.elems;
  if $nrows == 1 {
    $!grid-row-data[0][QAToolButtonAddColumn].show;
    $!grid-row-data[0][QAToolButtonDelColumn].show;
  }

  else {
    for ^$nrows -> $row {
      if $nrows - 1 == $row {
        $!grid-row-data[$row][QAToolButtonAddColumn].show;
      }

      else {
        $!grid-row-data[$row][QAToolButtonAddColumn].hide;
      }
    }
  }
}
