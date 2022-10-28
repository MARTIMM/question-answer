use v6;

#-------------------------------------------------------------------------------
use Gnome::Gtk3::Frame;
use Gnome::Gtk3::StyleContext;

#-------------------------------------------------------------------------------
unit role QA::Gui::Frame;
also is Gnome::Gtk3::Frame;

#-------------------------------------------------------------------------------
method new ( |c ) {
#note 'new QA::Gui::Frame';
  # let the Gnome::Gtk3::Frame class process the options
  self.bless( :GtkFrame, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( Str :$label = '' ) {

  # modify frame and title
  self.set-label-align( 0.04, 0.5);
  self.set-margin-bottom(3);
  #self.set-border-width(5);
  self.set-hexpand(True);
  self.set-label($label) if ?$label;

  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAFrame');
}
