#TL:2:QA::Gui::Value:

use v6.d;

use Gnome::N::N-GObject;

use Gnome::Gtk3::ComboBoxText;
use Gnome::Gtk3::Grid;
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
#CONTROL { when CX::Warn {  note .gist; .resume; } }

  my Str $message = '';

  my QA::Status $status .= instance;

  my Str $msg-id = '';

  if ! $status.get-faulty-state(self.question.name) {
note "status ok, now we check …";

    # check if there is a user routine which can check data. requiredness
    # must be checked too by the routine.
    if ?self.question.check-cb {
      my QA::Types $qa-types .= instance;
      #my Array $cb-spec = $qa-types.get-check-handler(self.question.check);
      #my ( $handler-object, $method-name, $options) = @$cb-spec;
      my ( $handler-object, $method-name, $options) =
        |$qa-types.get-check-handler(self.question.check-cb);
      $message = $handler-object."$method-name"( $input, |%$options) // '';
      $msg-id = self.question.name if ?$message;
note "status ok, now we check …";
    }

    # if there is no callback, check a widgets check method
    # cannot use .? pseudo op because the FALLBACK routine from the gnome
    # packages will spoil your ideas.
    if ! $msg-id and self.^lookup("check-value") {
      $message = self.check-value($input);
      $msg-id = self.question.name if ?$message;
    }

    # if there is no check mehod, check if it is required
    if ! $msg-id and ?self.question.required and $input ~~ m/^ \s* $/ {
      $msg-id = self.question.name;
      $message = "$msg-id is required";
    }
  }

  if ? $msg-id {
note "check message: ", self.question.name, ' == ', $msg-id;
    self.set-status-hint( $input-widget, QAStatusFail);
    $status.set-faulty-state( self.question.name, True);

    $msg-id = self.question.name;
    $status.send( %(
        :statusbar, :set-msg, :id<input-errors>, :$message, :$msg-id
      )
    );
  }

  else {
note "drop message: ", self.question.name, ' == ', $msg-id;
    $status.send( %(
        :statusbar, :drop-msg, :id<input-errors>, :msg-id(self.question.name)
      )
    );

    self.set-status-hint( $input-widget, QAStatusNormal);
    self!adjust-user-data( $input-widget, $input, $row);
    $status.set-faulty-state( self.question.name, False);
  }
}

#-------------------------------------------------------------------------------
method !adjust-user-data ( $input-widget, Any $input, Int() $row ) {

#CONTROL { when CX::Warn {  note .gist; .resume; } }

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

#-------------------------------------------------------------------------------
method create-widget ( |c ) { ... } #( Str $widget-name --> Any ) { ... }

#-------------------------------------------------------------------------------
method input-change-handler ( |c ) { ... }
