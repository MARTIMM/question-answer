#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
#use Gnome::Gtk3::ScrolledWindow;

use QA::Gui::Dialog;
use QA::Gui::Statusbar;
use QA::Gui::Page;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::DialogDisplay

=end pod

unit class QA::Gui::DialogDisplay:auth<github:MARTIMM>;
also is QA::Gui::Dialog;

#-------------------------------------------------------------------------------
has Gnome::Gtk3::Grid $!grid;
has $!sheet-dialog;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( :$!sheet-dialog, Int :$width, Int :$height ) {

  # todo width and height spec must go to sets
  self.set-dialog-size( $width, $height) if ?$width and ?$height;

  $!grid = self.dialog-content;

  # add some buttons specific for this notebook
  $!sheet-dialog.create-button(
    'cancel', 'cancel-dialog', GTK_RESPONSE_CANCEL, :default, :dialog(self)
  );

  $!sheet-dialog.create-button(
    'finish', 'finish-dialog', GTK_RESPONSE_OK, :dialog(self)
  );

  self.register-signal( $!sheet-dialog, 'dialog-response', 'response');
  my QA::Gui::Statusbar $statusbar .= instance;
  $!grid.grid-attach( $statusbar, 0, 1, 1, 1);
}

#-------------------------------------------------------------------------------
method add-page ( QA::Gui::Page $page ) {
#  my Gnome::Gtk3::ScrolledWindow $page-window = $page.create-content;
  $!grid.grid-attach( $page.create-content, 0, 0, 1, 1);
}
