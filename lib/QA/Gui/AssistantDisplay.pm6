#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;

#use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Assistant;

use QA::Types;

#use QA::Gui::Dialog;
#use QA::Gui::Statusbar;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::StackDisplay

=end pod

unit class QA::Gui::AssistantDisplay:auth<github:MARTIMM>;
#also is Gnome::Gtk3::Assistant;

#-------------------------------------------------------------------------------
#has Gnome::Gtk3::Grid $!grid;
has $!sheet-dialog;
has Gnome::Gtk3::Assistant $!assistant;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
#submethod new ( |c ) {
#  self.bless( :GtkAssistant, |c);
#}

#-------------------------------------------------------------------------------
submethod BUILD ( :$!sheet-dialog, Int :$width, Int :$height ) {

  # todo width and height spec must go to sets
#  self.set-dialog-size( $width, $height) if ?$width and ?$height;
  $!assistant .= new;
  $!assistant.widget-set-hexpand(True);
  $!assistant.widget-set-vexpand(True);

  if ? $width and ? $height {
    $!assistant.set-size-request( $width, $height);
    $!assistant.window-resize( $width, $height);
  }
}

#-------------------------------------------------------------------------------
method add-page (
  $page-window where .^name ~~ 'Gnome::Gtk3::ScrolledWindow',
  Str :$title, :$page-type
) {

  CATCH { .note; }

#Gnome::N::debug(:on);
  my Int $page-idx = $!assistant.append-page($page-window);
  my $no = $!assistant.get-nth-page($page-idx),
  $!assistant.set-page-type( $no, QAPageType.enums{$page-type});
  $!assistant.set-page-title( $no, $title);
#Gnome::N::debug(:off);
}

#-------------------------------------------------------------------------------
method show-all ( ) {
  $!assistant.show-all;
}
