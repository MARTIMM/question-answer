use v6.d;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

use Gnome::Gtk3::FileChooser;
use Gnome::Gtk3::FileChooserButton;

#-------------------------------------------------------------------------------
unit class QA::Gui::QAFileChooser;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
has QA::Question $.question;
has Hash $.user-data-set-part;

#-------------------------------------------------------------------------------
submethod BUILD ( QA::Question:D :$!question, Hash:D :$!user-data-set-part ) { }

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # create a text input widget
  my Gnome::Gtk3::FileChooserButton $filechooserbutton .= new(
    :title($!question.title)
  );
  $filechooserbutton.set-hexpand(True);
  $filechooserbutton.register-signal(
    self, 'input-change-handler', 'file-set', :$row
  );
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

#`{{
#-------------------------------------------------------------------------------
method clear-value ( Any:D $filechooserbutton ) {
}
}}

#-------------------------------------------------------------------------------
method input-change-handler ( :_widget($filechooserbutton), Int() :$row ) {
  self.process-widget-input(
    $filechooserbutton, self.get-value($filechooserbutton),
    $row, :do-check($!question.required)
  );
}
