#TL:2:QA::Gui::ValueTools:

use v6.d;

use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Enums;

use QA::Gui::Frame;
use QA::Gui::Statusbar;

use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
=begin pod

=head1 QA::Gui::ValueTools

Several methods for use by the other B<QA::Gui::…Value> roles.

=head1 Description

=comment head2 Uml Diagram

=comment ![](plantuml/Dialog.svg)

=comment head2 Example

=end pod

unit role QA::Gui::ValueTools:auth<github:MARTIMM>:ver<0.1.0>;
also is QA::Gui::Frame;

#-------------------------------------------------------------------------------
has Int $!msg-id;
has Bool $.faulty-state;
has Bool $.initialized is rw = False;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
#method setup-tools ( :$!widget-name ) { }

#-------------------------------------------------------------------------------
method initialize ( Bool :$single-value = True ) {
  #( QA::Question $question, Hash $user-data-set-part) {

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
  if $single-value {
    self!set-one-value(
      $input-widget, self.user-data-set-part{self.question.name}
    );
  }

  else {
  }

  # add a classname to this frame
  self.add-class( self, 'QAFrame');

  self.initialized = True;
}

#-------------------------------------------------------------------------------
# Single value. May still be an array but is to be given whole to the widget.
method !set-one-value ( $input-widget, $value ) {
note 'single value: ', self.^name;
  if ?$value {
    self.set-value( $input-widget, $value);
    self.check-widget-value($input-widget);
  }
}

#-------------------------------------------------------------------------------
=begin pod
=head2 create-widget-object

This is a general purpose widget creating method. It calls the method C<.create-widget()> of the B<QA::Gui::…Value> role client code for the creation details. That method returns the real widget. In this method, it sets a tooltip on the widget, if any, and set it to expand horizontally.

This method returns the input widget

  method create-widget-object ( --> Any )

Returns the input widget
=end pod

#TM:2:create-widget-object:
method create-widget-object ( ) { #( QA::Question $question --> Any ) {
#  my Str $widget-name = self.question.name;
CONTROL { when CX::Warn {  note .gist; .resume; } }

  self.set-name(self.question.name);
  my $input-widget = self.create-widget;  (self.question.name);
  my Str $tooltip = self.question.tooltip;
  $input-widget.set-tooltip-text($tooltip) if ?$tooltip;

  $input-widget
}

#-------------------------------------------------------------------------------
method adjust-user-data ( $input ) {

#  CONTROL { when CX::Warn {  note .gist; .resume; } }
  note "$?LINE, self.question.name, $input";

  self.user-data-set-part{self.question.name} = $input;
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
  if self.question.callback {
    my QA::Types $qa-types .= instance;
    #my Array $cb-spec = $qa-types.get-check-handler(self.question.callback);
    #my ( $handler-object, $method-name, $options) = @$cb-spec;
    my ( $handler-object, $method-name, $options) =
      |$qa-types.get-check-handler(self.question.callback);
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
  if !$!faulty-state and ?self.question.required {
    $!faulty-state = ($!faulty-state or (?self.question.required and !$input));
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
    $message = "self.question.description(): $message";
    $!msg-id = $statusbar.statusbar-push( $cid, $message) unless $!msg-id;
  }
#`{{
  elsif ? self.question.required or self.question.callback.defined {
    self.set-status-hint( $w, QAStatusOk);
#    self.adjust-user-data( self.question.name, $input);
  }
}}
  else {
    self.set-status-hint( $w, QAStatusNormal);
#    self.adjust-user-data( self.question.name, $input);
  }
}

#-------------------------------------------------------------------------------
method check-users-action ( $input, Str $action-key = '' ) {

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
          self.check-users-action( $input, $other-action-key);
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
    #self.adjust-user-data( self.question.name, $input);
    self.adjust-user-data($input);
    self.check-users-action( $input, self.question.action) if $!initialized;
  }
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
method create-widget ( ) { ... } #( Str $widget-name --> Any ) { ... }