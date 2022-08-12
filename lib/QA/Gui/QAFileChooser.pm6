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
method create-widget ( Int() :$row --> Any ) {

  # create a text input widget
  my $action;
note 'options: ', ($!question.options<action> // '-').raku;
  given $!question.options<action> {
    when 'open' {
      $action = GTK_FILE_CHOOSER_ACTION_OPEN;
    }

    when 'save' {
      $action = GTK_FILE_CHOOSER_ACTION_SAVE;
    }

    when 'select' {
      $action = GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER;
    }

    when 'create' {
      $action = GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER;
    }

    default {
      $action = GTK_FILE_CHOOSER_ACTION_OPEN;
    }
  }

  my Gnome::Gtk3::FileChooserButton $filechooserbutton .= new(
    :title($!question.title), :$action
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
method input-change-handler (
  Gnome::Gtk3::FileChooserButton() :_native-object($filechooserbutton),
  Int() :$row
) {
  self.process-widget-input(
    $filechooserbutton, self.get-value($filechooserbutton),
    $row, :do-check($!question.required)
  );
}
