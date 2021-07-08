use v6.d;

unit role QA::Gui::Repeat:auth<github:MARTIMM>;

use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ToolButton;
use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::Image;
use Gnome::Gtk3::Enums;

use QA::Types;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#`{{
a grid is used to cope with repeatable values.
The input fields are placed under each other in one
column. furthermore, a pulldown can be shown when the input can be
categorized.
}}

#-------------------------------------------------------------------------------
#`{{ A widget per row. When $!repeatable is True more than one.
  * col 1 (=QACatColumn); Place of a ComboBox. Optional.
  * col 2 (=QAInputColumn); Place of inut widget.
  * col 3 (=QAButtonColumn); Place of ToolButton when $!repeatable = True.
}}
has Gnome::Gtk3::Grid $!repeat-grid;
has Bool $!repeatable;

#`{{
  * $!row-count; nummber of rows in $!repeat-grid.
  * $!input-widgets; Widget array. These are the widgets in $!repeat-grid.
  * $!values; Values from the input widgets.
}}
has Int $!row-count;
has Array $!input-widgets;
has Array $!values;

#-------------------------------------------------------------------------------
submethod init-repeat ( Bool $!repeatable = False --> Gnome::Gtk3::Grid ) {
  $!row-count = 0;
  $!input-widgets = [];
  $!values = [];

  $!repeat-grid .= new;
  $!repeat-grid
}

#-------------------------------------------------------------------------------
# Create an imput row. Value $!row-count must be set to the proper row before
# calling.
method create-input-row ( $input-widget, $select-list is copy ) {

  # add to the grid
  $!repeat-grid.grid-attach( $input-widget, QAInputColumn, $!row-count, 1, 1);
  $!input-widgets[$!row-count] = $input-widget;

  # add a [+] button to the right when repeatable is set True
  if $!repeatable {
    my Gnome::Gtk3::ToolButton $tb = self!create-toolbutton;
    $!repeat-grid.grid-attach( $tb, QAButtonColumn, $!row-count, 1, 1);
  }

  # create comboboxes on the left when selectlist is a non-empty Array
  $select-list //= [];
  if $select-list.elems {
note $select-list.gist;
    my Gnome::Gtk3::ComboBoxText $cbt = self!create-combobox($select-list);
    $cbt.register-signal(
      self, 'combobox-change', 'changed', :$input-widget, :$!row-count
    );
    $!repeat-grid.grid-attach( $cbt, QACatColumn, $!row-count, 1, 1);
  }

  $!repeat-grid.show-all;
}

#-------------------------------------------------------------------------------
method !create-toolbutton ( --> Gnome::Gtk3::ToolButton ) {

  my Gnome::Gtk3::Image $image .= new;
  $image.set-from-icon-name( 'list-add', GTK_ICON_SIZE_BUTTON);

  my Gnome::Gtk3::ToolButton $tb .= new(:icon($image));
  self.add-class( $tb, 'QAToolButtonRowControl');
  $tb.set-name("tb:$!row-count");
  $tb.register-signal( self, 'add-row', 'clicked');

  $tb
}

#-------------------------------------------------------------------------------
method !create-combobox ( Array $select-list --> Gnome::Gtk3::ComboBoxText ) {

  my Gnome::Gtk3::ComboBoxText $cbt .= new;
  for @$select-list -> $select-item {
    $cbt.append-text($select-item);
  }

  self.add-class( $cbt, 'QAComboBoxText');
  $cbt.set-active(0);
  $cbt
}

#-------------------------------------------------------------------------------
method add-new-row ( --> Int ) {
  # Create a new input row if widget didn't exist. Number of rows
  # is equal to number of elements
  #my Int $row = $!input-widgets.elems;

  #if ! $!input-widgets[$!row-count].defined {
    self.create-widget-object($!row-count);
    self.check-widget-value( $!input-widgets[$!row-count], $!row-count);

    # get the toolbutton from the previous row to adjust its settings.
    # $row always > 0 because there is always one field created.
    #my Gnome::Gtk3::ToolButton $toolbutton .= new(
    #  :native-object($!repeat-grid.get-child-at( QAButtonColumn, $row - 1))
    #);
    my Gnome::Gtk3::ToolButton $toolbutton = $!repeat-grid.get-child-at-rk(
      QAButtonColumn, $!row-count - 1
    );

    # extend by emitting a signal which triggers the 'add-row' method.
    $toolbutton.emit-by-name('clicked');
  #}

  $!row-count++
}

#-------------------------------------------------------------------------------
# Repeating values,
method set-repeated-values ( Array $values is rw, $selectlist ) {
note 'array values: ', self.^name;
  #my Int $row = 0;
  my @ok-values = @$values;
  for @$values -> $value {
    # if empty or undefined, skip the value, don't save it
    next unless ?$value;

    # Check if row is 0. If so, row is already made. Otherwise create
    # a new row and new widget
    if $!row-count > 0 {
#`{{
      my Str $widget-name = $!question.name;
      self.set-name($widget-name);
      my $input-widget = self.create-widget($widget-name);
      self.set-hexpand(True);
      $row = self.create-input-row( $input-widget, $!question.selectlist);
}}
      self.create-widget-object($!row-count);
    }

    if $selectlist.defined {
      # no types, can be anything and undefined
      my ( $select-item, $input) = $value.kv;

      self.set-value( $!input-widgets[$!row-count], $input);
      self.check-widget-value( $!input-widgets[$!row-count], $!row-count);

      my Int $value-index =
        $selectlist.first( $select-item, :k) // 0;
      my Gnome::Gtk3::ComboBoxText $cbt =
        $!repeat-grid.get-child-at-rk( QACatColumn, $!row-count);
      $cbt.set-active($value-index);
    }

    else {
      self.set-value( $!input-widgets[$!row-count], $value);
      self.check-widget-value( $!input-widgets[$!row-count], $!row-count);
    }


    # save displayed value
    @ok-values.push($value);

    $!row-count++;
  }

  $values = @ok-values;
}

#-------------------------------------------------------------------------------
# Single value: $!row-count = 0;
method set-one-value ( Any $value where * !~~ Array ) {
note 'single value: ', self.^name;
  if ?$value {
    self.set-value( $!input-widgets[0], $value);
    self.check-widget-value( $!input-widgets[0], 0);
  }
}