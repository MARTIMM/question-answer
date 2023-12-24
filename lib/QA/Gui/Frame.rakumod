use v6;

#-------------------------------------------------------------------------------
use Gnome::Gtk4::Frame:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;

#-------------------------------------------------------------------------------
unit class QA::Gui::Frame;
also is Gnome::Gtk4::Frame;

#-------------------------------------------------------------------------------
submethod BUILD ( Str :$label = '' ) {

  # modify frame and title
  self.set-label-align( 0.04, 0.5);
  self.set-margin-bottom(3);
  #self.set-border-width(5);
  self.set-hexpand(True);
#  self.set-label($label) if ?$label;

  my Gnome::Gtk4::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAFrame');
}
