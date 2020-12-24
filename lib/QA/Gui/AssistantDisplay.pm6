#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::N-GObject;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Dialog;
#use Gnome::Gtk3::Grid;
use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Assistant;

use QA::Types;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;

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
has Array[QA::Gui::Page] $!pages;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
#submethod new ( |c ) {
#  self.bless( :GtkAssistant, |c);
#}

#-------------------------------------------------------------------------------
submethod BUILD ( :$!sheet-dialog, Int :$width, Int :$height ) {

  # todo width and height spec must go to sets
#  self.set-dialog-size( $width, $height) if ?$width and ?$height;
  $!pages = Array[QA::Gui::Page].new;

  given $!assistant .= new {
    .widget-set-hexpand(True);
    .widget-set-vexpand(True);

    if ? $width and ? $height {
      .set-size-request( $width, $height);
      .window-resize( $width, $height);
    }

    .register-signal( self, 'apply-input', 'apply');
    .register-signal( self, 'cancel-input', 'cancel');
    .register-signal( self, 'close-page', 'close');
    .register-signal( self, 'escape-page', 'escape');
    .register-signal( self, 'prepare-page', 'prepare');
  }
}

#-------------------------------------------------------------------------------
method add-page ( QA::Gui::Page $page, Str :$title, :$page-type ) {

#  CATCH { .note; }

#Gnome::N::debug(:on);
  state Int $page-count = 0;
  my Gnome::Gtk3::ScrolledWindow $page-window = $page.create-content;
  $page-window.set-name("$page-count");
  $!pages.push: $page;
  $page-count++;

#  my Int $page-idx = $!assistant.append-page($page-window);
#  my $no = $!assistant.get-nth-page($page-idx),
#  $!assistant.set-page-type( $no, QAPageType.enums{$page-type});

  $!assistant.append-page($page-window);
  $!assistant.set-page-type( $page-window, QAPageType.enums{$page-type});
  $!assistant.set-page-title( $page-window, $title);
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
method apply-input ( Gnome::Gtk3::Assistant :_widget($assistant) ) {
note 'apply';
  $!sheet-dialog.save-data;
}

#-------------------------------------------------------------------------------
method cancel-input ( Gnome::Gtk3::Assistant :_widget($assistant) ) {
note 'cancel';
  $!assistant.widget-destroy if $!sheet-dialog.show-cancel;
}

#-------------------------------------------------------------------------------
method close-page ( Gnome::Gtk3::Assistant :_widget($assistant) ) {
note 'close';
  $!assistant.widget-destroy;
}

#-------------------------------------------------------------------------------
method escape-page ( Gnome::Gtk3::Assistant :_widget($assistant) ) {
note 'escape';

}

#-------------------------------------------------------------------------------
method prepare-page (
  N-GObject $no-page, Gnome::Gtk3::Assistant :_widget($assistant)
) {
note 'prepare';

  my Gnome::Gtk3::ScrolledWindow $page-window .= new(:native-object($no-page));
  my Int $page-idx = $page-window.get-name.Int;
note "I: $page-idx, ", $!pages[$page-idx].gist;

  if $!pages[$page-idx].query-page-state {
    $assistant.set-page-complete( $page-window, False);
  }

  else {
    $assistant.set-page-complete( $page-window, True);
  }
}
