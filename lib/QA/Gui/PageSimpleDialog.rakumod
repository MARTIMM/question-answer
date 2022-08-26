#tl:1:QA::Gui::PageSimpleDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Button;

use QA::Set;
use QA::Types;
use QA::Status;

use QA::Gui::Dialog;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::PageTools;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageSimpleDialog

=end pod

unit class QA::Gui::PageSimpleDialog:auth<github:MARTIMM>;
also is QA::Gui::Dialog;
also does QA::Gui::PageTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;
has Any $!result-handler-object;
has Str $!result-handler-method;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
  Any :$!result-handler-object?, Str :$!result-handler-method?
) {
  $!qst .= new(:$!qst-name);

  self.load-user-data($user-data);
  self.set-style('QAPageSimple');

  with $!qst {
    self.set-dialog-size( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  self.set-grid(self);
  self.set-grid-content(self);

  # add some buttons specific for this notebook
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL);
  self.add-button( 'save-continue', GTK_RESPONSE_APPLY);
  self.add-button( 'save-quit', GTK_RESPONSE_OK);
  self.add-button( 'help-info', GTK_RESPONSE_HELP);
}

#-------------------------------------------------------------------------------
method add-button ( Str $widget-name, GtkResponseType $response-type ) {
note "add button $widget-name";

  # it is possible that button is undefined
  my Gnome::Gtk3::Button $button = self.create-button($widget-name);
  with $button {
    my Hash $button-map = $!qst.button-map // %();
    if ? $button-map{$widget-name}<default> {
      .set-can-default(True);
      self.set-default-response($response-type);
    }

    self.add-action-widget( $button, $response-type);
  }
}

#-------------------------------------------------------------------------------
method show-sheet ( ) {

  my QA::Status $status .= instance;
  $status.clear-status;

  loop {
    given my Int $response-type = GtkResponseType(self.show-dialog) {
      when GTK_RESPONSE_DELETE_EVENT {
        self.hide;
        sleep(0.3);
        self.destroy;
        last;
      }

      when GTK_RESPONSE_OK {
        if $status.faulty-state {
          self.show-message(
            "There are still missing or wrong answers, cannot save data"
          );
        }

        else {
          self.save-data;
          if ?$!result-handler-object and
              $!result-handler-object.^can($!result-handler-method) {
            $!result-handler-object."$!result-handler-method"(
              $!result-user-data
            );
          }

          self.destroy;
          last;
        }
      }

      when GTK_RESPONSE_APPLY {
        if $status.faulty-state {
          self.show-message(
            "There are still missing or wrong answers, cannot save data"
          );
        }

        else {
          self.save-data;
          if ?$!result-handler-object and
              $!result-handler-object.^can($!result-handler-method) {
            $!result-handler-object."$!result-handler-method"(
              $!result-user-data
            );
          }
        }
      }

      when GTK_RESPONSE_CANCEL {
        if self.show-cancel {
          self.destroy;
          last;
        }
      }

      when GTK_RESPONSE_HELP {
        my Str $text = $!qst.button-map<help-info><message>;
        self.show-message($text) if ?$text;
      }

      default {
        die "Response type '$_' not supported";
      }
    }
  }
}

#-------------------------------------------------------------------------------
method show-message ( Str:D $message --> Int ) {
  my QA::Gui::OkMsgDialog $ok .= new(:$message);
  my $r = $ok.run;
  $ok.destroy;

  $r
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {

  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.run);
    $yn.destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}
