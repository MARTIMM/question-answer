#tl:1:QA::Gui::PageDialog
use v6.d;

#use Gnome::N::X;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;

use QA::Types;
use QA::Status;

use QA::Gui::Dialog;
use QA::Gui::PageTools;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageStackDialog

=end pod

unit class QA::Gui::PageStackDialog:auth<github:MARTIMM>;
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
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
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
  # :default now in config button map
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL);
  self.add-button( 'save-continue', GTK_RESPONSE_APPLY);
  self.add-button( 'save-quit', GTK_RESPONSE_OK);
  self.add-button( 'help-info', GTK_RESPONSE_HELP);
}
