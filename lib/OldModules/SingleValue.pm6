use v6.d;

use Gnome::Gtk3::Enums;

#use QA::Gui::Statusbar;
#use QA::Gui::Frame;
#use QA::Gui::ValueTools;
use QA::Types;
use QA::Question;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
=begin pod

=end pod

unit role QA::Gui::SingleValue:auth<github:MARTIMM>;
#also is QA::Gui::Frame;
#also does QA::Gui::ValueTools;

#-------------------------------------------------------------------------------
#has $!input-widget;

#`{{
#-------------------------------------------------------------------------------
has $!input-widget;
has $!value;
has QA::Question $.question;
#has Str $!widget-name;
#has Gnome::Gtk3::Grid $!grid;
#has Int $!msg-id;
has Hash $.user-data-set-part;
#has Bool $!initialized = False;

# state of current variable. value is True when answer is incorrect
#has Bool $.faulty-state;
}}

#`{{
#-------------------------------------------------------------------------------
method initialize ( ) { #( QA::Question $question, Hash $user-data-set-part) {

  # check if things are defined properly. must be done here because
  # user defined widgets may forget to handle them
  die 'question data not defined'
    unless ?self.question and ?self.question.name;
#  die 'user data not defined' unless ?$!user-data-set-part;

  # clear values
#  $!input-widgets = [];
#  $!values = [];

  # Initialize repetition and add a grid to the frame.
  #self.add(self.init-repeat($!question.repeatable));

#  my $widget-name = self.question.name;
#  self.setup-tools(:$widget-name);

  # make frame invisible if not repeatable
  self.set-shadow-type(GTK_SHADOW_NONE);
  self.set-hexpand(True);

#`{{
  # fiddle a bit
  self.set-name($!widget-name);
  self.set-hexpand(True);

  # add a grid to the frame. a grid is used to cope with repeatable values.
  # the input fields are placed under each other in one column. furthermore,
  # a pulldown can be shown when the input can be categorized.
  #$!grid .= new;
  #self.add($!grid);

  my $input-widget = self.create-widget($!widget-name);
  my Str $tooltip = $!question.tooltip;
  $input-widget.set-tooltip-text($tooltip) if ?$tooltip;
  $input-widget.set-name("$!widget-name:0");
  self.create-input-row( $input-widget, $!question.selectlist);
}}
  my $input-widget = self.create-widget-object; #(self.question);
  $input-widget.set-name(self.question.name);
  self.add($input-widget);


  # fill in user data
  self.set-one-value(
    $input-widget, self.user-data-set-part{self.question.name}
  );

  # add a classname to this frame
  self.add-class( self, 'QAFrame');

  self.initialized = True;
}
}}

#-------------------------------------------------------------------------------
# Single value. May still be an array but is to be given whole to the widget.
method set-one-value ( $input-widget, $value ) {
note 'single value: ', self.^name;
  if ?$value {
    self.set-value( $input-widget, $value);
    self.check-widget-value($input-widget);
  }
}

















=finish

#-------------------------------------------------------------------------------
method create-widget-object ( ) {
#  my Str $widget-name = $!question.name;
CONTROL { when CX::Warn {  note .gist; .resume; } }
  self.set-name($!widget-name);
  $!input-widget = self.create-widget($!widget-name);
  my Str $tooltip = $!question.tooltip;
  $!input-widget.set-tooltip-text($tooltip) if ?$tooltip;
  $!input-widget.set-name($!widget-name);
  self.set-hexpand(True);

  # Create an imput row and add input widget to the grid
#    $!repeat-grid.grid-attach( $!input-widget, QAInputColumn, 0, 1, 1);
#    $!repeat-grid.show-all;
  self.add($!input-widget);
}

#-------------------------------------------------------------------------------
method check-widget-value ( $w, :$input is copy ) {

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
    #my Array $cb-spec = $qa-types.get-check-handler($!question.callback);
    #my ( $handler-object, $method-name, $options) = @$cb-spec;
    my ( $handler-object, $method-name, $options) =
      |$qa-types.get-check-handler($!question.callback);
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
    self.set-status-hint( $w, QAStatusFail);
    # don't add a new message if there is already a message placed
    # on the statusbar
    $message = "$!question.description(): $message";
    $!msg-id = $statusbar.statusbar-push( $cid, $message) unless $!msg-id;
  }
#`{{
  elsif ? $!question.required or $!question.callback.defined {
    self.set-status-hint( $w, QAStatusOk);
#    self.adjust-user-data( $!widget-name, $input);
  }
}}
  else {
    self.set-status-hint( $w, QAStatusNormal);
#    self.adjust-user-data( $!widget-name, $input);
  }
}

#-------------------------------------------------------------------------------
method set-status-hint ( $widget, InputStatusHint $status ) {
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
# called when a selection changes in the input widget combobox.
# it must adjust the user data. no checks are needed.
method process-widget-signal (
  $widget, Bool :$do-check = False, :$input is copy
) {
  $input //= self.get-value($widget);
  self.check-widget-value( $widget, :$input) if $do-check;
  note "$?LINE, faulty: {$!faulty-state//'-'}";

  if ! $!faulty-state {
    #self.adjust-user-data( $!widget-name, $input);
    self.adjust-user-data($input);
    self.check-users-action( $input, $!question.action) if $!initialized;
  }
}

#-------------------------------------------------------------------------------
method !check-users-action ( $input, Str $action-key = '' ) {

  # check if there is a user routine to run any actions
  if ? $action-key {
    my Array $followup-actions = self.run-users-action( $input, $action-key);

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

        when QAEnableInputWidget {
        }

        when QADisableInputWidget {
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
method run-users-action ( $input, Str:D $action-key = '' --> Array ) {

  return [] unless ?$action-key;

  my QA::Types $qa-types .= instance;
  my Array $action-spec = $qa-types.get-action-handler($action-key);
  my ( $handler-object, $method-name, $options) = @$action-spec;

  $handler-object."$method-name"( $input, |%$options) // []
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
method create-widget ( Str $widget-name --> Any ) { ... }
