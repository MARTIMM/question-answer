use v6;

#-------------------------------------------------------------------------------
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::QALabel;
also is Gnome::Gtk4::Label;

#-------------------------------------------------------------------------------
submethod BUILD ( *%options ) {
  with self {
    .set-use-markup(%options<do-markup>:exists);
    .set-hexpand(True);
    .set-line-wrap(True);
    #.set-max-width-chars(40);
    .set-justify(GTK_JUSTIFY_FILL);
    .set-halign(GTK_ALIGN_START);
    .set-valign(GTK_ALIGN_START);
    .set-margin-top(6);
    .set-margin-start(2);

    Gnome::Gtk4::StyleContext.new(
      :native-object(.get-style-context)
    ).add-class('QAQuestionLabel');
  }
}
