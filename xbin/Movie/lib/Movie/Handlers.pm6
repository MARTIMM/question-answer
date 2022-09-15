use v6.d;

use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Main;
#use Gnome::Gtk3::Enums;
#use Gnome::Gtk3::Window;
#use Gnome::Gtk3::Grid;
#use Gnome::Gtk3::Button;

use QA::Gui::SheetNotebook;
#use QA::Gui::Frame;
#use QA::Gui::Value;
#use QA::Types;
#use QA::Question;

#-------------------------------------------------------------------------------
unit class Movie::Handlers:auth<github:MARTIMM>:ver<0.1.0>;

#-------------------------------------------------------------------------------
method show-movie-form ( ) {
  my QA::Gui::SheetNotebook $dialog .= new(
    :sheet-name<movie>, :show-cancel-warning, :save-data
  );

  my Int $response = $dialog.show-qst;
  self!display-result( $response, $dialog);
}

#-------------------------------------------------------------------------------
method !display-result ( Int $response, QA::Gui::SheetNotebook $dialog ) {

  note "Dialog return status: ", GtkResponseType($response);
  return unless $response ~~ GTK_RESPONSE_OK;

  my $i = 0;
  sub show-hash ( Hash $h ) {
    $i++;
    for $h.keys.sort -> $k {
      if $h{$k} ~~ Hash {
        note '  ' x $i, "$k => \{";
        show-hash($h{$k});
        note '  ' x $i, '}';
      }

      elsif $h{$k} ~~ Array {
        note '  ' x $i, "$k => $h{$k}.perl()";
      }

      else {
        note '  ' x $i, "$k => $h{$k}";
      }
    }
    $i--;
  }

  show-hash($dialog.result-user-data);
  $dialog.widget-destroy;
}

#-------------------------------------------------------------------------------
method exit-app ( ) {
  Gnome::Gtk3::Main.new.gtk-main-quit;
}

#`{{
#-------------------------------------------------------------------------------
# check methods
method check-char ( Str $input, :$char --> Any ) {
  "No $char allowed in string" if ?($input ~~ m/$char/)
}

#-------------------------------------------------------------------------------
# action methods
method fieldtype-action1 ( Str $input --> Array ) {
  note "Selected 1: $input";

  [%( :type(QAOtherUserAction), :action-key<show-select2>),]
}

#-------------------------------------------------------------------------------
method fieldtype-action2 ( Str $input, :$opt1 --> Array ) {
  note "Selected 2: $input, option: $opt1";

  [%(),]
}
}}
