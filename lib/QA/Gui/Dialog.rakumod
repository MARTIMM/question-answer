use v6.d;

use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
#use Gnome::Gtk4::Widget:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::Box:api<2>;

use Gnome::N::X;
use Gnome::N::N-GObject;

use Gnome::Glib::Error;

#-------------------------------------------------------------------------------
=begin pod
Purpose of this class is to be a base class for all dialogs (except from other gtk modules like MessageDialog or AboutDialog) used in this application and library so as to show a uniform look. There is a content area which is set as a grid and a button area.
=end pod

unit class QA::Gui::Dialog:auth<github:MARTIMM>;
also is Gnome::Gtk4::Dialog;

has Gnome::Gtk4::Grid $.dialog-content;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( ) {

#  self.set-dialog-size( 300, 300);
  self.set-keep-above(True);
  self.set-position(GTK_WIN_POS_MOUSE);
#  self.set-size-request( $width, $height);
#  self.window-resize( $width, $height);

  my Gnome::Glib::Error $e = self.set-icon-from-file(
    %?RESOURCES<icons8-invoice-100.png>.Str
  );
  die $e.message if $e.is-valid;

  # a grid is placed in this dialog
  $!dialog-content .= new;
  $!dialog-content.widget-set-hexpand(True);
  $!dialog-content.widget-set-vexpand(True);

  my Gnome::Gtk4::Box $content .= new(:native-object(self.get-content-area));
  $content.widget-set-name('dialog-content-area');
  self!cleanup-content($content);
  $content.add($!dialog-content);

  my Gnome::Gtk4::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QADialog');
}

#-------------------------------------------------------------------------------
method set-dialog-size ( Int $width = 300, Int $height = 300 ) {
  self.set-size-request( $width, $height);
  self.window-resize( $width, $height);
}

#-------------------------------------------------------------------------------
method add-dialog-button (
  Any $handler-object, Str $handler-method, Str $button-text, Int $response-type
) {

  my Gnome::Gtk4::Button $b .= new(
    :native-object(self.add-button( $button-text, $response-type))
  );
  $b.register-signal( $handler-object, $handler-method, 'clicked');
}

#-------------------------------------------------------------------------------
method show-dialog ( --> Int ) {

  self.show-all;
  my Int $response-type = self.run;

#  self.gtk-widget-destroy;

  $response-type
}

#-------------------------------------------------------------------------------
method !cleanup-content ( $content ) {

  class Wipe {

    method wipe-widget ( N-GObject $nw ) {
      my Gnome::Gtk4::Widget $w .= new(:native-object($nw));
      $w.widget-destroy if $w.widget-get-name eq 'dialog-content-area';
    }
  }

  $content.foreach( Wipe.new, 'wipe-widget');
}
