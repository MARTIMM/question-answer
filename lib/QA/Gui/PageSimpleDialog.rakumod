#tl:1:QA::Gui::PageSimpleDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;

use QA::Status;

use QA::Gui::Dialog;
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
