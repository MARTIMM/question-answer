use v6;

#-------------------------------------------------------------------------------
use Gnome::Gtk3::Label;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::Enums;

#-------------------------------------------------------------------------------
unit class QA::Gui::QALabel;
also is Gnome::Gtk3::Label;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::Label class process the options
  self.bless( :GtkLabel, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( ) {

  given self {
    #.set-use-markup(True);
    .set-hexpand(True);
    .set-line-wrap(True);
    #.set-max-width-chars(40);
    .set-justify(GTK_JUSTIFY_FILL);
    .set-halign(GTK_ALIGN_START);
    .set-valign(GTK_ALIGN_START);
    .set-margin-top(6);
    .set-margin-start(2);

    Gnome::Gtk3::StyleContext.new(
      :native-object(.get-style-context)
    ).add-class('labelText');
  }
}
