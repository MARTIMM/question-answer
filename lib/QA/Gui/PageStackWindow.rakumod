#tl:1:QA::Gui::PageDialog
use v6.d;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Dialog;

#use QA::Status;
use QA::Gui::PageTools;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageStackWindow

=end pod

unit class QA::Gui::PageStackWindow:auth<github:MARTIMM>;
also does QA::Gui::PageTools;

#-------------------------------------------------------------------------------
has Int $!response;
has Gnome::Gtk3::Widget $!widget;

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
  Gnome::Gtk3::Widget :$!widget,
) {
  $!qst .= new( :$!qst-name, :versioned);
  self.load-user-data;
  self.set-style( 'QAPageStack', :$!widget);

  with $!qst {
    $!widget.set-border-width(2);
    $!widget.set-size-request( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  self.set-grid($!widget);
  self.set-grid-content('Stack');

  # add some buttons specific for this notebook
  self.add-button( 'cancel', GTK_RESPONSE_CANCEL, :!is-dialog);
  self.add-button( 'save-continue', GTK_RESPONSE_APPLY, :!is-dialog);
  self.add-button( 'save-quit', GTK_RESPONSE_OK, :!is-dialog);
  self.add-button( 'help-info', GTK_RESPONSE_HELP, :!is-dialog);

# QA::Status.instance.clear-status;
}
