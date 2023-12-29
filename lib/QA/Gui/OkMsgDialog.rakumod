use v6.d;
use NativeCall;

#-------------------------------------------------------------------------------
use Gnome::N::N-Object:api<2>;
use Gnome::N::GlibToRakuTypes:api<2>;

use Gnome::Glib::N-Error:api<2>;

use Gnome::GdkPixbuf::Pixbuf:api<2>;

use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::T-Dialog:api<2>;
use Gnome::Gtk4::MessageDialog:api<2>;
use Gnome::Gtk4::T-MessageDialog:api<2>;
#use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::OkMsgDialog;
also is Gnome::Gtk4::MessageDialog;

#-------------------------------------------------------------------------------
submethod new ( Str $message, Mu $parent = N-Object ) {

  # Let the Gnome::Gtk4::MessageDialog class process the options
  self.new-with-markup(
    $parent, GTK_DIALOG_MODAL, GTK_MESSAGE_WARNING, GTK_BUTTONS_OK, $message
  )
}

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {
  self.set-default-response(GTK_RESPONSE_NO);

#`{{
  my $e = CArray[N-Error].new(N-Error);
  my Gnome::GdkPixbuf::Pixbuf $win-icon .= new-from-file(
    %?RESOURCES<icons8-invoice-100.png>.Str, $e
  );
  if ?$e[0] {
    note "Error icon file: $e[0].message()";
  }

  else {
    self.set-icon-name($win-icon);
  }
}}

#  self.set-icon-name('qa');
  self.register-signal( self, 'ok-done', 'response');

  my Gnome::Gtk4::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAMsgDialog');
}

#-------------------------------------------------------------------------------
method ok-done ( gint $response-id ) {
  note "$?LINE $response-id";
  self.destroy;
}
