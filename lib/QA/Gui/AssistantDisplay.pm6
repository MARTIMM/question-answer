#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

#use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Assistant;

use QA::Types;
use QA::Gui::Page;

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
  given $!assistant .= new {
    .widget-set-hexpand(True);
    .widget-set-vexpand(True);

    if ? $width and ? $height {
      .set-size-request( $width, $height);
      .window-resize( $width, $height);
    }

    .register-signal( self, 'apply-inut', 'apply');
    .register-signal( self, 'cancel-inut', 'cancel');
    .register-signal( self, 'close-page', 'close');
    .register-signal( self, 'escape-page', 'escape');
    .register-signal( self, 'prepare-page', 'prepare');
  }
}

#-------------------------------------------------------------------------------
method add-page ( QA::Gui::Page $page, Str :$title, :$page-type ) {

#  CATCH { .note; }

#Gnome::N::debug(:on);
  my Int $page-idx = $!assistant.append-page($page.create-content);
  my $no = $!assistant.get-nth-page($page-idx),
  $!assistant.set-page-type( $no, QAPageType.enums{$page-type});
  $!assistant.set-page-title( $no, $title);
#Gnome::N::debug(:off);
}

#-------------------------------------------------------------------------------
method show-all ( ) {
  $!assistant.show-all;
}

#-------------------------------------------------------------------------------
method widget-destroy ( ) {
  $!assistant.widget-destroy;
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method apply-inut (
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'apply';

}

#-------------------------------------------------------------------------------
method cancel-inut (
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'cancel';

}

#-------------------------------------------------------------------------------
method close-page (
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'close';

}

#-------------------------------------------------------------------------------
method escape-page (
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'escape';

}

#-------------------------------------------------------------------------------
method prepare-page (
  N-GObject $no-page, Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'prepare';

  my Gnome::Gtk3::ScrolledWindow $page-window .= new(:native-object($no-page));
}
