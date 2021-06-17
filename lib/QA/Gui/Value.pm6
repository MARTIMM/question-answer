use v6.d;

#TODO is encoding a string necessary? isn't it users aftermath?
#TODO when to fill in default values? also users work later?

#use Gnome::Gtk3::Widget;
#use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ToolButton;
use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::Image;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Enums;

use QA::Gui::Statusbar;
use QA::Gui::Frame;
use QA::Types;
use QA::Question;

use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
=begin pod

=end pod

unit role QA::Gui::Value:auth<github:MARTIMM>;
also is QA::Gui::Frame;

#-------------------------------------------------------------------------------
has Gnome::Gtk3::Grid $!grid;
has QA::Question $!question;

has Str $!widget-name;

has Array $!values;
has Hash $!user-data-set-part;
has Array $!input-widgets;

# state of current variable. value is True when answer is incorrect
has Bool $.faulty-state;

has Bool $!initialized = False;

has Int $!msg-id;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::Frame class process the options
  self.bless( :GtkFrame, |c);
}

#-------------------------------------------------------------------------------
method initialize ( ) {

  # check if things are defined properly. must be done here because
  # user defined widgets may forget to handle them
  die 'question data not defined' unless ?$!question and ?$!question.name;
#  die 'user data not defined' unless ?$!user-data-set-part;

  # clear values
  $!input-widgets = [];
  $!values = [];

  $!widget-name = $!question.name;

  # make frame invisible if not repeatable
  self.set-shadow-type(GTK_SHADOW_NONE) unless ?$!question.repeatable;

  # fiddle a bit
  self.set-name($!widget-name);
  self.set-hexpand(True);

  # add a grid to the frame. a grid is used to cope with repeatable values.
  # the input fields are placed under each other in one column. furthermore,
  # a pulldown can be shown when the input can be categorized.
  $!grid .= new;
  self.add($!grid);
  self!create-input-row(0);

  # fill in user data
  self!set-values;

  # add a classname to the frame
  self.add-class( self, 'QAFrame');

  $!initialized = True;
}

#-------------------------------------------------------------------------------
method !create-input-row ( Int $row ) {

  # create input widget and add or change some general items
  my $input-widget = self.create-widget( "$!widget-name:$row", $row);

  my Str $tooltip = $!question.tooltip;
  $input-widget.set-tooltip-text($tooltip) if ?$tooltip;
  $input-widget.set-name("$!widget-name:$row");
  #self.add-class( $input-widget, $!question.fieldtype.Str);

  # add to the grid
  $!grid.grid-attach( $input-widget, QAInputColumn, $row, 1, 1);
  $!input-widgets[$row] = $input-widget;

  # add a [+] button to the right when repeatable is set True
  if $!question.repeatable {
    my Gnome::Gtk3::ToolButton $tb = self!create-toolbutton($row);
    $!grid.grid-attach( $tb, QAButtonColumn, $row, 1, 1);
  }

  # create comboboxes on the left when selectlist is a non-empty Array
  my Array $select-list = $!question.selectlist // [];
  if $select-list.elems {
    my Gnome::Gtk3::ComboBoxText $cbt = self!create-combobox($select-list);
    $cbt.register-signal(
      self, 'combobox-change', 'changed', :$input-widget, :$row
    );
    $!grid.grid-attach( $cbt, QACatColumn, $row, 1, 1);
  }

  $!grid.show-all;
}

#-------------------------------------------------------------------------------
method !set-values ( ) {

  # check if the value is an array
  my $v = $!user-data-set-part{$!question.name};
  my @values = $v ~~ Array ?? @$v !! ($v);
  if $!question.repeatable {
    my Bool $spliced = False;
    my Int $row = 0;

    # loop like this because we might take out empty items
    loop {
      last if $row >= @values.elems;

      # check for empty data
      my ( $select-item, $input);
      if ?$!question.selectlist {
        ( $select-item, $input) = @values[$row].kv;

        unless $input {
          @values.splice( $row, 1);
          $spliced = True;
          next;
        }
      }

      else {
        unless ?@values[$row] {
          @values.splice( $row, 1);
          $spliced = True;
          next;
        }
      }


      # create a new input row if widget didn't exist
      self.add-new-row($row);

      # set value in field widget
      if $!question.selectlist.defined {
        # no types, can be anything and undefined
        #my ( $select-item, $input) = @values[$row].kv;

        self.set-value( $!input-widgets[$row], $input);
        self!check-value( $!input-widgets[$row], $row);

        my Int $value-index =
          $!question.selectlist.first( $select-item, :k) // 0;
        my Gnome::Gtk3::ComboBoxText $cbt .= new(
          :native-object($!grid.get-child-at( QACatColumn, $row))
        );
        $cbt.set-active($value-index);
      }

      else {
        self.set-value( $!input-widgets[$row], @values[$row]);
        self!check-value( $!input-widgets[$row], $row);
      }

      $row++;
      last if $row >= @values.elems;
    }

    $!user-data-set-part{$!question.name} = [|@values] if $spliced;
  }

  # set a single field and check
  elsif $v.defined {
    self.set-value( $!input-widgets[0], $v);
    self!check-value( $!input-widgets[0], 0);
  }

  # check field too when no value is set. now also required fields
  # turns in faulty state beforehand
  else {
    self!check-value( $!input-widgets[0], 0);
  }
}

#-------------------------------------------------------------------------------
method add-new-row ( Int $row ) {
  # create a new input row if widget didn't exist
  if ! $!input-widgets[$row].defined {

    # get the toolbutton from the previous row to adjust its settings.
    # $row always > 0 because there is always one field created.
    #my Gnome::Gtk3::ToolButton $toolbutton .= new(
    #  :native-object($!grid.get-child-at( QAButtonColumn, $row - 1))
    #);
    my Gnome::Gtk3::ToolButton $toolbutton = $!grid.get-child-at-rk(
      QAButtonColumn, $row - 1
    );

    # extend by emitting a signal which triggers the 'add-row' method.
    $toolbutton.emit-by-name('clicked');
  }
}

#-------------------------------------------------------------------------------
method !create-toolbutton ( $row --> Gnome::Gtk3::ToolButton ) {

  my Gnome::Gtk3::Image $image .= new;
  $image.set-from-icon-name( 'list-add', GTK_ICON_SIZE_BUTTON);

  my Gnome::Gtk3::ToolButton $tb .= new(:icon($image));
  self.add-class( $tb, 'QAToolButtonRowControl');
  $tb.set-name("tb:$row");
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
method !adjust-user-data ( $w, $input, Int $row ) {

  if ? $!question.repeatable {
    if $!question.selectlist.defined {
      my Gnome::Gtk3::ComboBoxText $cbt .= new(
        :native-object($!grid.get-child-at( QACatColumn, $row))
      );

      my Str $select-item = $cbt.get-active-text // $!question.selectlist[0];
      $!user-data-set-part{$!widget-name}[$row] = $select-item => $input;
    }

    else {
      $!user-data-set-part{$!widget-name}[$row] = $input;
    }
  }

  else {
    $!user-data-set-part{$!widget-name} = $input;
  }
}

#-------------------------------------------------------------------------------
method !check-value ( $w, Int $row, :$input is copy ) {

  $!faulty-state = False;

  # if not delivered, get the value ourselves
  $input //= self.get-value($w);
  my Str $message;

  # get a context id. same string returns same context id.
  my QA::Gui::Statusbar $statusbar .= instance;
  my Int $cid = $statusbar.get-context-id('input errors');

  # check if there is a user routine which can check data. requiredness
  # must be checked too by the routine.
  if $!question.callback {
    my QA::Types $qa-types .= instance;
    my Array $cb-spec = $qa-types.get-check-handler($!question.callback);
    my ( $handler-object, $method-name, $options) = @$cb-spec;
    $message = $handler-object."$method-name"( $input, |%$options) // '';

    # if routine founds an error, a message returns.
    $!faulty-state = True if ?$message;
  }

  # if there is no callback, check a widgets check method
  # cannot use .? pseudo op because the FALLBACK routine from the gnome
  # packages will spoil your ideas.
  if !$!faulty-state and self.^lookup("check-value") {
    $message = self.check-value($input);
    $!faulty-state = True if ?$message;
  }

  # if there is no check mehod, check if it is required
  if !$!faulty-state and ?$!question.required {
    $!faulty-state = ($!faulty-state or (?$!question.required and !$input));
    $message = "is required" if $!faulty-state;
  }

  # no errors, check if there is a message id from previous mesage, remove it.
  if !$!faulty-state and ?$!msg-id {
    $statusbar.remove( $cid, $!msg-id);
    $!msg-id = 0;
  }


  if $!faulty-state {
    self!set-status-hint( $w, QAStatusFail);
    # don't add a new message if there is already a message placed
    # on the statusbar
    $message = "$!question.description(): $message";
    $!msg-id = $statusbar.statusbar-push( $cid, $message) unless $!msg-id;
  }
#`{{
  elsif ? $!question.required or $!question.callback.defined {
    self!set-status-hint( $w, QAStatusOk);
#    self!adjust-user-data( $w, $input, $row);
  }
}}
  else {
    self!set-status-hint( $w, QAStatusNormal);
#    self!adjust-user-data( $w, $input, $row);
  }
}

#-------------------------------------------------------------------------------
method !check-users-action ( $input, Str $action-key = '' ) {

  # check if there is a user routine to run any actions
  if ? $!question.action {
    my Array $followup-actions = self!run-users-action( $input, $action-key);

    for @$followup-actions -> Hash $action {
      given $action<type> {
        when QAOpenDialog {
        }

        when QAHidePage {
        }

        when QAShowPage {
        }

        when QAHideSet {
        }

        when QAShowSet {
        }

        when QAEnableButton {
        }

        when QADisableButton {
        }

        when QAOtherUserAction {
          my Str $other-action-key = $action<action-key>;
          self!check-users-action( $input, $other-action-key);
        }
      }
    }
  }
}

#-------------------------------------------------------------------------------
method !run-users-action ( $input, Str:D $action-key = '' --> Array ) {

  return [] unless ?$action-key;

  my QA::Types $qa-types .= instance;
  my Array $action-spec = $qa-types.get-action-handler($action-key);
  my ( $handler-object, $method-name, $options) = @$action-spec;

  $handler-object."$method-name"( $input, |%$options) // []
}

#-------------------------------------------------------------------------------
method !set-status-hint ( $widget, InputStatusHint $status ) {
  # remove classes first
  #$context.remove-class('dontcare');
  self.remove-class( $widget, 'QAStatusNormal');
  self.remove-class( $widget, 'QAStatusOk');
  self.remove-class( $widget, 'QAStatusFail');

  # add class depending on status
  if $status ~~ QAStatusNormal {
    self.add-class( $widget, 'QAStatusNormal');
  }

  elsif $status ~~ QAStatusOk {
    self.add-class( $widget, 'QAStatusOk');
  }

  elsif $status ~~ QAStatusFail {
    self.add-class( $widget, 'QAStatusFail');
  }

#  else {
#  }
}

#-------------------------------------------------------------------------------
#--[ Abstract Methods ]---------------------------------------------------------
#-------------------------------------------------------------------------------
# no typing of arguments because widget can be any input widget and value
# can be any of text-, number- or boolean
method set-value ( Any:D $widget, Any:D $value ) { ... }

#-------------------------------------------------------------------------------
# no typing for return value because it can be a single value, an Array of
# single values or and Array of Pairs.
method get-value ( $widget --> Any ) { ... }

#-------------------------------------------------------------------------------
method create-widget ( Str $widget-name, Int $row --> Any ) { ... }

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method add-row ( Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id ) {

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
}

#-------------------------------------------------------------------------------
method delete-row ( Gnome::Gtk3::ToolButton :_widget($tb), Int :$_handler-id ) {

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
}

#-------------------------------------------------------------------------------
# called when a selection changes in the $!question.selectlist combobox.
# it must adjust the selection value. no check is needed because
# input field is not changed.
method combobox-change ( :_widget($w), :$input-widget, Int :$row --> Int ) {

  self.process-widget-signal( $input-widget, $row, :!do-check);

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}

#-------------------------------------------------------------------------------
# called when a selection changes in the input widget combobox.
# it must adjust the user data. no checks are needed.
method process-widget-signal (
  $w, Int $row, Bool :$do-check = False, :$input is copy
) {
  $input //= self.get-value($w);
  self!check-value( $w, $row, :$input) if $do-check;
  unless $!faulty-state {
    self!adjust-user-data( $w, $input, $row);
    self!check-users-action( $input, $!question.action) if $!initialized;
  }
}

#-------------------------------------------------------------------------------
method add-class ( $widget, Str $class-name ) {
  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object($widget.get-style-context)
  );
  $context.add-class($class-name);
}

#-------------------------------------------------------------------------------
method remove-class ( $widget, Str $class-name ) {
  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object($widget.get-style-context)
  );
  $context.remove-class($class-name);
}
