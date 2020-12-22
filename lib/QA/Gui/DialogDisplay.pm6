#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Button;
#use Gnome::Gtk3::Notebook;
#use Gnome::Gtk3::Stack;
#use Gnome::Gtk3::StackSwitcher;
#use Gnome::Gtk3::Assistant;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
#use Gnome::Gtk3::Builder;

#use QA::Set;
#use QA::Sheet;
use QA::Types;

#use QA::Gui::Set;
#use QA::Gui::Question;
use QA::Gui::Dialog;
#use QA::Gui::Frame;
use QA::Gui::Statusbar;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::DialogDisplay

=end pod

unit class QA::Gui::DialogDisplay:auth<github:MARTIMM>;
also is QA::Gui::Dialog;

#-------------------------------------------------------------------------------
#has QA::Sheet $!sheet;
has Gnome::Gtk3::Grid $!grid;

has $!sheet-dialog;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( :$!sheet-dialog, Int :$width, Int :$height ) {
note "S: ", self.gist, ', ', $!sheet-dialog.gist;

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
method add-page ( Gnome::Gtk3::ScrolledWindow $page-window ) {

  $page-window.widget-set-hexpand(True);
  $page-window.widget-set-vexpand(True);

  $!grid.grid-attach( $page-window, 0, 0, 1, 1);
}
