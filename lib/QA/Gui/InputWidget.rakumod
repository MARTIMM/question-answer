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
#use QA::Gui::QAFileChooser;
#use QA::Gui::QAImage;

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
#| Array of question parameters
has QA::Question $!question;

#| Location in larger Hash, a location for the answer on this question
has Hash $!user-data-set-part;

#| The place to hold the widget object
has $!widget-object;

#| Grid rows holding the real input widgets
has Array $!grid-row-data;

#| The grid which displays the input widgets and other sub widgets
has Gnome::Gtk3::Grid $!grid;

#| state of the input widgets held in the $!grid-row-data
has Bool $.faulty-state = False;

#-------------------------------------------------------------------------------
submethod BUILD ( QA::Question:D :$!question, Hash:D :$!user-data-set-part ) {
  $!grid-row-data = [];
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
    # Add at least one row if widget object is valid
    self!append-grid-row;

    # And set values from user data.
    self!apply-values;
  }

  $!faulty-state = False;
}

#-------------------------------------------------------------------------------
method !create-widget-object ( ) {
  my Str $module-name = 'QA::Gui::' ~ $!question.fieldtype.Str;
  if (my $m = ::($module-name)).^lookup('set-value') ~~ Method {
    $!widget-object = ::($module-name).new( :$!question, :$!user-data-set-part);
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
method !append-grid-row ( ) {
  my Int $current-row = $!grid-row-data.elems;
note "append-grid-row, nrows: $current-row";

  given my $input-widget = $!widget-object.create-widget(:row($current-row)) {
    my Str $tooltip = $!question.tooltip;
    .set-tooltip-text($tooltip) if ?$tooltip;
    .set-name($!question.name);
    .set-hexpand(True);
  }

  $!grid-row-data[$current-row] = [];
  $!grid-row-data[$current-row][QAInputColumn] = $input-widget;

  $!grid.attach( $input-widget, QAInputColumn, $current-row, 1, 1);

  if $!question.repeatable {
    my Gnome::Gtk3::ToolButton $tb;
    $tb = self!create-toolbutton( $current-row, :add);
    $!grid.grid-attach( $tb, QAToolButtonAddColumn, $current-row, 1, 1);
    $!grid-row-data[$current-row][QAToolButtonAddColumn] = $tb;

    $tb = self!create-toolbutton($current-row, :!add);
    $!grid.grid-attach( $tb, QAToolButtonDelColumn, $current-row, 1, 1);
    $!grid-row-data[$current-row][QAToolButtonDelColumn] = $tb;
  }

  $!grid.show-all;

  self.hide-tb-add;
#  for ^$!grid-row-data.elems -> $row {
#    last if $row == $!grid-row-data.elems - 1;
#    $!grid-row-data[$row][QAToolButtonAddColumn].hide;
#  }
}

#-------------------------------------------------------------------------------
method !create-toolbutton (
  Int $row, Bool :$add = True
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
    .register-signal( self, $tb-handler, 'clicked', :$row);
    .register-signal( self, 'hide-tb-add', 'show', :$row)
      if $tb-name eq 'tb-add';
#    .show;
  }

  $!widget-object.add-class( $tb, 'QAToolButtonRowControl');

  $tb
}

#-------------------------------------------------------------------------------
method !create-combobox ( Array $select-list --> Gnome::Gtk3::ComboBoxText ) {

  my Gnome::Gtk3::ComboBoxText $cbt .= new;
  for @$select-list -> $select-item {
    $cbt.append-text($select-item);
  }

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
      self!append-grid-row if $i > 0;

      my $input-widget = $!grid-row-data[$i][QAInputColumn];
      $!widget-object.set-value( $input-widget, $values[$i]);
      $!widget-object.check-widget-value(
        $input-widget, $values[$i], :row($i)
      );
      $i++;
    }

    # Restore to remove any undefined or empty values
    $!user-data-set-part{$!question.name} = $values;
  }

  else {
note 'single value: ', ($!widget-object.^name, $!user-data-set-part{$!question.name}).join(', ');

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
method add-row (
  Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id, Int :$row
) {
note "add row, name: $tb.get-name()";
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

  self!append-grid-row;
#  $tb.hide;

#`{{
  my $next-row = $!grid-row-data.elems;

  my Gnome::Gtk3::ToolButton $tb2;
  $tb2 = self!create-toolbutton( $next-row, :add);
  $!grid.grid-attach( $tb2, QAToolButtonAddColumn, $next-row, 1, 1);
  $tb2 = self!create-toolbutton($next-row, :!add);
  $!grid.grid-attach( $tb2, QAToolButtonDelColumn, $next-row, 1, 1);
}}

}

#-------------------------------------------------------------------------------
method del-row (
  Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id, Int :$row
) {
note "delete row, name: $tb.get-name()";

  $!grid-row-data[$row][QAToolButtonAddColumn].hide;

  $!grid-row-data[$row][QAInputColumn].destroy;
  if $!question.repeatable {
    $!grid-row-data[$row][QAToolButtonAddColumn].destroy;
    $!grid-row-data[$row][QAToolButtonDelColumn].destroy;

    $!grid-row-data[$row][QACatColumn].destroy
      if $!question.selectlist.defined;
  }

  $!user-data-set-part{$!question.name}.splice( $row, 1);

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
# Called from !append-grid-row() or as a callback from the 'show' event
# when .show-all() is called.
method hide-tb-add ( ) {
  for ^$!grid-row-data.elems -> $row {
    last if $row == $!grid-row-data.elems - 1;
    $!grid-row-data[$row][QAToolButtonAddColumn].hide;
  }
}
