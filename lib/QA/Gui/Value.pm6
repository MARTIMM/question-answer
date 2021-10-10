#TL:2:QA::Gui::Value:

use v6.d;

use Gnome::N::N-GObject;

use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Enums;

#use QA::Gui::Frame;
#use QA::Gui::Statusbar;
use QA::Status;

use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
=begin pod

=head1 QA::Gui::Value

Several methods to handle the widgets value.

=head1 Description

=comment head2 Uml Diagram

=comment ![](plantuml/Dialog.svg)

=comment head2 Example

=end pod

unit role QA::Gui::Value:auth<github:MARTIMM>:ver<0.1.0>;
#also is QA::Gui::Frame;

#-------------------------------------------------------------------------------
has Str $!msg-id;
#has Bool $.faulty-state = False;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
# Called when an input widget has new data. It must adjust the user data Hash.
# Optionally checks are performed on the incoming data.
method process-widget-input (
  $input-widget, Any $input is copy, Int() $row, Bool :$do-check = False
) {
#CONTROL { when CX::Warn {  note .gist; .resume; } }
#note "$?LINE, process-widget-signal, {$input//'-'}, $row";

  $input //= '';

  self.check-widget-value( $input-widget, $input, :$row) if $do-check;
  my QA::Status $status .= instance;
  unless $status.get-faulty-state(self.question.name) {
    self!adjust-user-data( $input-widget, $input, $row);
    self.check-users-action( $input, self.question.action);
  }
}

#-------------------------------------------------------------------------------
method check-widget-value (
  Any:D $input-widget, Any:D $input, Int() :$row = -1
) {
CONTROL { when CX::Warn {  note .gist; .resume; } }
#note "$?LINE, check-widget-value, $input, $row";

#  $!faulty-state = False;

  # if not delivered, get the value ourselves
  #$input //= self.get-value($input-widget);
  my Str $message;

  # get a context id. same string returns same context id.
#  my QA::Gui::Statusbar $statusbar .= instance;
#  my Int $cid = $statusbar.get-context-id('input errors');
  my QA::Status $status .= instance;

  # check if there is a user routine which can check data. requiredness
  # must be checked too by the routine.
  if self.question.callback {
    my QA::Types $qa-types .= instance;
    #my Array $cb-spec = $qa-types.get-check-handler(self.question.callback);
    #my ( $handler-object, $method-name, $options) = @$cb-spec;
    my ( $handler-object, $method-name, $options) =
      |$qa-types.get-check-handler(self.question.callback);
    $message = $handler-object."$method-name"( $input, |%$options) // '';

    # if routine finds an error, state is faulty and a message returns.
    $status.set-faulty-state( self.question.name, True) if ?$message;
  }

  # if there is no callback, check a widgets check method
  # cannot use .? pseudo op because the FALLBACK routine from the gnome
  # packages will spoil your ideas.
  if !$status.get-faulty-state(self.question.name)
     and self.^lookup("check-value") {

    $message = self.check-value($input);
    $status.set-faulty-state( self.question.name, True) if ?$message;
  }

  # if there is no check mehod, check if it is required
  if !$status.get-faulty-state(self.question.name) and ?self.question.required {
    $status.set-faulty-state(
      self.question.name, ( ?self.question.required and !$input )
    );
    $message = "is required" if $status.get-faulty-state(self.question.name);
  }

  # no errors, check if there is a message id from previous mesage, remove it.
  if !$status.get-faulty-state(self.question.name) and ?$!msg-id {
#    $statusbar.remove( $cid, $!msg-id);
    $status.send( %(
        :statusbar, :id<input-errors>, :message($!msg-id => '')
      )
    );
    $!msg-id = '';
  }

#note "F: $!faulty-state, ", self.question.name;
  if $status.get-faulty-state(self.question.name) {
    self.set-status-hint( $input-widget, QAStatusFail);
    # don't add a new message if there is already a message placed
    # on the statusbar
#    $message = self.question.description ~ ": $message";
    $message = self.question.name ~ ": $message";
    #$!msg-id = $statusbar.statusbar-push( $cid, $message) unless $!msg-id;
    $!msg-id = $message;
    $status.send( %(
        :statusbar, :id<input-errors>, :message($!msg-id => $message)
      )
    );
  }
#`{{
  elsif ? self.question.required or self.question.callback.defined {
    self.set-status-hint( $input-widget, QAStatusOk);
#    self!adjust-user-data( $input-widget, $input, $row);
  }
}}
  else {
    self.set-status-hint( $input-widget, QAStatusNormal);
    self!adjust-user-data( $input-widget, $input, $row);
    $status.set-faulty-state( self.question.name, False);
  }
}

#-------------------------------------------------------------------------------
method !adjust-user-data ( $input-widget, Any $input, Int() $row ) {

CONTROL { when CX::Warn {  note .gist; .resume; } }
#note "\n$?LINE, adjust-user-data, $input, $row";

  my Str $name = self.question.name;
  if ? self.question.repeatable {
    if ? self.question.selectlist {
      my Gnome::Gtk3::Grid $grid = $input-widget.get-parent-rk;
      my Gnome::Gtk3::ComboBoxText $cbt = $grid.get-child-at-rk(
        QACatColumn, $row, :child-type<Gnome::Gtk3::ComboBoxText>
      );
      my Str $select = self.question.selectlist[$cbt.get-active];
      self.user-data-set-part{$name}[$row] = $select => $input;
    }

    else {
      self.user-data-set-part{$name}[$row] = $input;
    }
  }

  else {
    self.user-data-set-part{$name} = $input;
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
method set-status-hint ( $input-widget, InputStatusHint $status ) {
  # remove classes first
  #$context.remove-class('dontcare');
  self.remove-class( $input-widget, 'QAStatusNormal');
  self.remove-class( $input-widget, 'QAStatusOk');
  self.remove-class( $input-widget, 'QAStatusFail');

  # add class depending on status
  if $status ~~ QAStatusNormal {
    self.add-class( $input-widget, 'QAStatusNormal');
  }

  elsif $status ~~ QAStatusOk {
    self.add-class( $input-widget, 'QAStatusOk');
  }

  elsif $status ~~ QAStatusFail {
    self.add-class( $input-widget, 'QAStatusFail');
  }
}

#-------------------------------------------------------------------------------
method add-class ( $input-widget, Str $class-name ) {
  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object($input-widget.get-style-context)
  );
  $context.add-class($class-name);
}

#-------------------------------------------------------------------------------
method remove-class ( $input-widget, Str $class-name ) {
  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object($input-widget.get-style-context)
  );
  $context.remove-class($class-name);
}

#-------------------------------------------------------------------------------
#--[ Abstract Methods ]---------------------------------------------------------
#-------------------------------------------------------------------------------
# no typing of arguments because widget can be any input widget and value
# can be any of text-, number- or boolean
method set-value ( Any:D $input-widget, Any:D $value ) { ... }

#`{{
#-------------------------------------------------------------------------------
# no typing for return value because it can be a single value, an Array of
# single values or and Array of Pairs.
method get-value ( $input-widget --> Any ) { ... }
}}

#-------------------------------------------------------------------------------
#method clear-value ( |c ) { ... }

#-------------------------------------------------------------------------------
method create-widget ( |c ) { ... } #( Str $widget-name --> Any ) { ... }

#-------------------------------------------------------------------------------
method input-change-handler ( |c ) { ... }
