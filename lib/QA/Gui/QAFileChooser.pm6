use v6.d;

use Gnome::Gtk3::FileChooser;
use Gnome::Gtk3::FileChooserButton;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

#-------------------------------------------------------------------------------
unit class QA::Gui::QAFileChooser;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part
) {
  self.initialize;
}

#-------------------------------------------------------------------------------
method create-widget ( Str $widget-name, Int $row --> Any ) {

  # create a text input widget
  my Gnome::Gtk3::FileChooserButton $filechooserbutton .= new(
    :title($!question.title)
  );
  $filechooserbutton.set-hexpand(True);
  $filechooserbutton.register-signal( self, 'file-selected', 'file-set');
  self.add-class( $filechooserbutton, 'QAFileChooserButton');

  $filechooserbutton
}

#-------------------------------------------------------------------------------
method get-value ( $filechooserbutton --> Any ) {
  $filechooserbutton.get-filename;
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $filechooserbutton, $filename ) {

  $filechooserbutton.set-filename($filename) if ?$filename;
}

#-------------------------------------------------------------------------------
method file-selected ( :_widget($filechooserbutton) ) {
  my ( $n, $row ) = $filechooserbutton.get-name.split(':');
  self.process-widget-signal(
    $filechooserbutton, $row.Int, :do-check($!question.required)
  );
}
