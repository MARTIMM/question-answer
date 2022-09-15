#tl:1:QA::Gui::PageDialog
use v6.d;

use QA::Gui::Dialog;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::PageTools;

#use Gnome::N::X;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Button;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageNotebookDialog

=end pod

unit class QA::Gui::PageNotebookDialog:auth<github:MARTIMM>;
also is QA::Gui::Dialog;
also does QA::Gui::PageTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True
) {
  $!qst .= new( :$!qst-name, :versioned);

  self.load-user-data($user-data);
  self.set-style('QAPageStack');

  with $!qst {
    self.set-dialog-size( .width, .height);
  }

  # set the grid and fill it
  self.set-grid(self);
  self.set-grid-content(self);

  # add some buttons specific for this stack
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL);
  self.add-button( 'save-continue', GTK_RESPONSE_APPLY);
  self.add-button( 'save-quit', GTK_RESPONSE_OK);
  self.add-button( 'help-info', GTK_RESPONSE_HELP);
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
