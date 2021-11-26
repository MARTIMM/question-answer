#tl:1:QA::Gui::SheetSimpleDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Button;

use QA::Set;
use QA::Sheet;
use QA::Types;
use QA::Status;

use QA::Gui::Dialog;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::SheetTools;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::SheetSimpleDialog

=end pod

unit class QA::Gui::SheetSimpleDialog:auth<github:MARTIMM>;
also is QA::Gui::Dialog;
also does QA::Gui::SheetTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;
has Int $!response;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!sheet-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True
) {
  $!sheet .= new(:$!sheet-name);
  self.load-user-data($user-data);
  self.set-style('QASheetSimple');

  # todo width and height spec must go to sets
  with $!sheet {
    self.set-dialog-size( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  self.set-grid(self);
  self.set-grid-content(self);

  # add some buttons specific for this notebook
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL, :default);
  self.add-button( 'finish', GTK_RESPONSE_OK);
}

#-------------------------------------------------------------------------------
method add-button (
  Str $widget-name, GtkResponseType $response-type, Bool :$default = False
) {

  my Gnome::Gtk3::Button $button = self.create-button($widget-name);

  if $default {
    $button.set-can-default(True);
    self.set-default-response($response-type);
  }

  self.add-action-widget( $button, $response-type);
}

#-------------------------------------------------------------------------------
method show-sheet ( --> Int ) {

  my QA::Status $status .= instance;

  loop {
    $status.clear-status;

    given GtkResponseType($!response = self.show-dialog) {
      when GTK_RESPONSE_DELETE_EVENT {
        self.hide;
        last;
      }

      when GTK_RESPONSE_OK {
        if $status.faulty-state {
          my QA::Gui::OkMsgDialog $ok .= new(
            :message(
              "There are still missing or wrong answers, cannot save data"
            )
          );

          $ok.dialog-run;
          $ok.destroy;
        }

        else {
          self.save-data;

          # must hide instead of destroy, otherwise the return status
          # is set to GTK_RESPONSE_NONE
          self.hide;
          last;
        }
      }

      when GTK_RESPONSE_CANCEL {
        if self.show-cancel {
          self.hide;
          last;
        }
      }
    }
  }

  $!response
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method dialog-response ( gint $response, QA::Gui::Dialog :_widget($dialog) ) {

  if GtkResponseType($response) ~~ GTK_RESPONSE_DELETE_EVENT {
    $!response = $response;

    $dialog.hide;
    sleep(0.3);
    $dialog.destroy;
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_OK {

    my QA::Status $status .= instance;
    if $status.faulty-state {
      my QA::Gui::OkMsgDialog $ok .= new(
        :message("There are still missing or wrong answers, cannot save data")
      );

      $ok.dialog-run;
      $ok.destroy;
    }

    else {
      self.save-data;
      $!response = $response;

      # must hide instead of destroy, otherwise the return status
      # is set to GTK_RESPONSE_NONE
      $dialog.hide;
    }
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_CANCEL {
    if self.show-cancel {
      $!response = $response;
      self.hide;
    }
  }
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {
  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.dialog-run);
    $yn.destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}
