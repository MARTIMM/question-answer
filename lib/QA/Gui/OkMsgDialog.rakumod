use v6.d;

#-------------------------------------------------------------------------------
use Gnome::Glib::Error;

use Gnome::Gdk3::Pixbuf;

use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::MessageDialog:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::OkMsgDialog;
also is Gnome::Gtk4::MessageDialog;

#-------------------------------------------------------------------------------
submethod new ( Str :$message, |c ) {

  # let the Gnome::Gtk4::MessageDialog class process the options
  self.bless(
    :GtkMessageDialog, :flags(GTK_DIALOG_MODAL), :type(GTK_MESSAGE_WARNING),
    :buttons(GTK_BUTTONS_OK), :markup-message($message),
    |c
    );
}

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {
  self.set-position(GTK_WIN_POS_MOUSE);
  self.set-keep-above(True);
  self.set-default-response(GTK_RESPONSE_NO);

  my Gnome::Gdk3::Pixbuf $win-icon .= new(
    :file(%?RESOURCES<icons8-invoice-100.png>.Str)
  );
  my Gnome::Glib::Error $e = $win-icon.last-error;
  if $e.is-valid {
    note "Error icon file: $e.message()";
  }

  else {
    self.set-icon($win-icon);
  }

  my Gnome::Gtk4::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAMsgDialog');
}

#-------------------------------------------------------------------------------
