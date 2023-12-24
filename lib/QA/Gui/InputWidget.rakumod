use v6;

use Gnome::Gdk3::Events;

use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::Entry:api<2>;
use Gnome::Gtk4::Grid:api<2>;
#use Gnome::Gtk4::ComboBoxText:api<2>;
use Gnome::Gtk4::ToolButton:api<2>;
use Gnome::Gtk4::Image:api<2>;

use QA::Types;
use QA::Question;

use QA::Gui::Frame;
#use QA::Gui::Question;
use QA::Gui::QAImage;
#use QA::Gui::QAComboBox;
use QA::Gui::QAEntry;
use QA::Gui::QAFileChooser;
use QA::Gui::QACheckButton;
use QA::Gui::QARadioButton;
use QA::Gui::QASpinButton;
use QA::Gui::QASwitch;
use QA::Gui::QATextView;
use QA::Gui::QASelectComboBox;

#-------------------------------------------------------------------------------
unit class QA::Gui::InputWidget:auth<github:MARTIMM>;
also is QA::Gui::Frame;

constant \QASelectComboBox = QA::Gui::QASelectComboBox;

#-------------------------------------------------------------------------------
# Question parameters
has QA::Question $!question;

# Location in larger Hash, a location for the answer on this question
has Hash $!user-data-set-part;

# The place to hold the widget object
has $!widget-object;

# Grid rows holding the real input widgets
has Array $!grid-row-data;
has Array $!grid-access-index;

# The grid which displays the input widgets and other sub widgets
has Gnome::Gtk4::Grid $!grid;

# state of the input widgets held in the $!grid-row-data
has Bool $.faulty-state = False;

# When filling in values from user data, the combobox events will fire when
# selection is changed. Use this flag to stop responding when it is not needed.
#has Bool $!inhibit-combobox-events = False;

has QASelectComboBox $!combobox;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part,
  :$gui-question where .^name eq 'QA::Gui::Question'
) {

  $!grid-row-data = [];
  $!grid-access-index = [];
  $!grid .= new;

  # place the grid in frame
  self.add($!grid);

  # set the name of this Frame to the widgets name
  self.set-name($!question.name);

  # make frame invisible if input is not repeatable
  unless ?$!question.repeatable {
    self.set-shadow-type(GTK_SHADOW_NONE);
    self.set-hexpand(True);
  }

  if $!question.fieldtype eq QAUserWidget {
    # If this is a user widget, the widget object is already created.
    self!create-user-widget-object(:$gui-question);
  }

  else {
    # Otherwise create the widget object
    self!create-widget-object(:$gui-question);
  }

  if ? $!widget-object {
    # Add at least one row if widget object is valid
    self.append-grid-row;

    # And set values from user data.
    self!apply-values;
  }

  $!faulty-state = False;
}

#-------------------------------------------------------------------------------
method !create-widget-object (
  :$gui-question # where .^name eq 'QA::Gui::Question' # checked at BUILD
) {
  my Str $module-name = 'QA::Gui::' ~ $!question.fieldtype.Str;
  if (my $m = ::($module-name)).^lookup('set-value') ~~ Method {
    $!widget-object = ::($module-name).new;
    $!widget-object.question = $!question;
    $!widget-object.user-data-set-part = $!user-data-set-part;
    $!widget-object.gui-input-widget = self;
    $!widget-object.gui-question = $gui-question;
  }

  else {
    # handle failure
    $m.Bool;
    die "fail to use  $module-name";
  }
}

#-------------------------------------------------------------------------------
method !create-user-widget-object (
  :$gui-question # where .^name eq 'QA::Gui::Question' # checked at BUILD
) {
  # Get the object from the questions userwidget field and get the object,
  # then call .init-widget() if the method is defined.
  my QA::Types $qa-types .= instance;
  $!widget-object = $qa-types.get-widget-object($!question.userwidget);
  if ?$!widget-object and $!widget-object.^lookup('create-widget') ~~ Method {
  #  $!widget-object.init-widget;
    $!widget-object.question = $!question;
    $!widget-object.user-data-set-part = $!user-data-set-part;
    $!widget-object.gui-input-widget = self;
    $!widget-object.gui-question = $gui-question;
  }

  else {
    die "failed to use QAUserWidget, $!question.userwidget().create-widget\()";
  }
}

#-------------------------------------------------------------------------------
method append-grid-row ( --> List ) {

CONTROL { when CX::Warn {  note .gist; .resume; } }

  my Int $current-grid-row = $!grid-row-data.elems;
  my Int $current-grid-index = $!grid-access-index.elems;
  $!grid-access-index[$current-grid-index] = $current-grid-row;

  with my $input-widget = $!widget-object.create-widget(
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

  if ?$!question.repeatable {
    # create comboboxes on the left when selectlist is a non-empty Array
    my Array $select-list = $!question.selectlist // [];
    if $select-list.elems {
      $!combobox .= new(
        :$select-list, :$input-widget, :$!widget-object,
        :$!grid, :$current-grid-row, :$current-grid-index,
        :use-entry
      );

      $!grid-row-data[$current-grid-row][QACatColumn] = $!combobox;
    }

    my Gnome::Gtk4::ToolButton $tb;
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

  self.hide-tb-add if ?$!question.repeatable;

  ( $input-widget, $current-grid-row, $current-grid-index)
}

#-------------------------------------------------------------------------------
method !create-toolbutton (
  Int $row-grid, Int $row-index, Bool :$add = True
  --> Gnome::Gtk4::ToolButton
) {

  my Gnome::Gtk4::Image $image .= new;
  my Str ( $tb-name, $tb-handler);

  # add '+' (add) button
  if $add {
    $image.set-from-icon-name( 'list-add', GTK_ICON_SIZE_BUTTON);
    $tb-name = 'tb-add';
    $tb-handler = 'add-row';
  }

  #  add '-' (remove) button
  else {
    $image.set-from-icon-name( 'list-remove', GTK_ICON_SIZE_BUTTON);
    $tb-name = 'tb-del';
    $tb-handler = 'del-row';
  }

  with my Gnome::Gtk4::ToolButton $tb .= new(:icon($image)) {
    .set-name($tb-name);
    .register-signal( self, $tb-handler, 'clicked', :$row-index);
    .register-signal( self, 'hide-tb-add', 'show');
    # if $tb-name eq 'tb-add';
  }

  $!widget-object.add-class( $tb, 'QAToolButtonRowControl');

  $tb
}


#-------------------------------------------------------------------------------
method !apply-values ( ) {

CONTROL { when CX::Warn {  note .gist; .resume; } }

  if ?$!question.repeatable {
#note "\nrepeated values: ", ($!widget-object.^name, $!user-data-set-part{$!question.name}).join(', ');

    # Make sure the input values is an Array, if not, create empty and return.
    my $values = $!user-data-set-part{$!question.name};
    if !$values or $values !~~ Array {
      $!user-data-set-part{$!question.name} = [];
      return;
    }

    # Loop through the values to set the input widgets
    my Int $i = 0;
    while $i < $values.elems {
note "\napply-values: $i, $values[$i].raku(), {($!question.selectlist // []).raku()}";

      my $input-widget;
      my $value;
      if ? $!question.selectlist {
        my ( $select-item, $select-input) = $values[$i].kv;

        # Skip empty/undefined values
note "apply-values: $i, $select-item => ", $select-input ?? $select-input !! '---';
        unless ?$select-input {
          $values.splice( $i, 1);
          next;
        }

        # First row is always created. When more than 1 value, create more rows
        self.append-grid-row if $i > 0;
        $input-widget = $!grid-row-data[$i][QAInputColumn];
        $value = $select-input;

        my Int $value-index = $!question.selectlist.first( $select-item, :k);
note "apply-values: $i, $select-item, ", $value-index // 'Undefined index';
        if $value-index {
          $!combobox.set-active($value-index);
        }

        else {
          $!combobox.append-text($select-item);
          $!combobox.set-active($!question.selectlist.elems);
          $!question.selectlist.push: $select-item;
        }
      }

      else {
        # Skip empty/undefined values
        unless ?$values[$i] {
          $values.splice( $i, 1);
          next;
        }

        # First row is always created. When more than 1 value, create more rows
        self.append-grid-row if $i > 0;
        $input-widget = $!grid-row-data[$i][QAInputColumn];
        $value = $values[$i];
      }


#note "v: $?LINE, $input-widget, $value";
      $!widget-object.set-value( $input-widget, $value);
      $!widget-object.check-widget-value( $input-widget, $value, :row($i));
      $i++;
    }

    # Restore to remove any undefined or empty values
    $!user-data-set-part{$!question.name} = $values;
  }

  else {
    my $value = $!user-data-set-part{$!question.name} // '';
#note "\nsingle values: ", ($!widget-object.^name, '$value').join(', ');

    my $input-widget = $!grid-row-data[0][QAInputColumn];
    $!widget-object.set-value( $input-widget, $value);
    $!widget-object.check-widget-value( $input-widget, $value, :row(0));
  }
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method add-row (
#  Gnome::Gtk4::ToolButton() :_native-object($tb),
#   Int :$_handler-id, Int :$row-index
) {
  self.append-grid-row
}

#-------------------------------------------------------------------------------
method del-row (
  Gnome::Gtk4::ToolButton() :_native-object($tb), Int :$_handler-id, Int :$row-index
) {
  my Int $row-grid = $!grid-access-index[$row-index];
#note "delete row: $row-index, $row-grid, $!grid-access-index.elems(), $!grid-row-data.elems()";

  # remove all widgets from this row except the last one
  if $!grid-row-data.elems() > 1 {
    $!grid-row-data[$row-grid][QAInputColumn].destroy;
    $!grid-row-data[$row-grid][QAToolButtonAddColumn].destroy;
    $!grid-row-data[$row-grid][QAToolButtonDelColumn].destroy;
    $!grid-row-data[$row-grid][QACatColumn].destroy if $!question.selectlist.defined;
    $!grid-row-data.splice( $row-grid, 1);

    for ($row-index..^$!grid-access-index.elems) -> $index {
      $!grid-access-index[$index]--;
    }
  }

  else {
    $!widget-object.clear-value($!grid-row-data[$row-grid][QAInputColumn])
      if $!widget-object.^can('clear-value') and
         ? $!grid-row-data[$row-grid][QAInputColumn];
  }

  # cut out the data of this row
  my $array := $!user-data-set-part{$!question.name};
  $array.splice( $row-grid, 1) if ?$array;

  self.hide-tb-add;
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
