#tl:1:QA::Gui::PageDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Label;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;

use QA::Types;
use QA::Status;

use QA::Gui::Set;
use QA::Gui::Question;
use QA::Gui::Frame;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::Statusbar;
use QA::Gui::PageTools;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageStackWindow

=end pod

unit class QA::Gui::PageStackWindow:auth<github:MARTIMM>;
also does QA::Gui::PageTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;
has Int $!response;
has Gnome::Gtk3::Widget $!widget;

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
  Gnome::Gtk3::Widget :$!widget,
) {
  $!qst .= new( :$!qst-name, :versioned);
  self.load-user-data($user-data);
  self.set-style('QAPageStack');

  with $!qst {
    $!widget.set-border-width(2);
    $!widget.set-size-request( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  $!widget.set-grid(self);
  $!widget.set-grid-content(self);

  # add some buttons specific for this stack
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL, :default);
  self.add-button( 'save-quit', GTK_RESPONSE_OK);
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
method show-sheet ( ) {

CATCH { .note; }
#note 'show sheet';

  my QA::Status $status .= instance;
  $status.clear-status;

  loop {
    given GtkResponseType(self.show-dialog) {
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

          $ok.run;
          $ok.hide;
          $ok.clear-object;
        }

        else {
          self.hide;
          self.save-data;
          last;
        }
      }

      when GTK_RESPONSE_CANCEL {
        if self.show-cancel {
          self.hide;
          last;
        }
      }

      default {
        die "Response type '$_' not supported";
      }
    }
  }
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {

  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.run);
    $yn.widget-destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}
