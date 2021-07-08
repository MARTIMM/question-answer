use v6.d;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::TextBuffer;
use Gnome::Gtk3::TextView;
use Gnome::Gtk3::TextIter;

use Gnome::Gdk3::Events;

use QA::Types;
use QA::Question;
use QA::Gui::SingleValue;

#-------------------------------------------------------------------------------
unit class QA::Gui::QATextView;
also does QA::Gui::SingleValue;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part
) {
  $!question.repeatable = False;
  self.initialize;
}

#-------------------------------------------------------------------------------
method create-widget ( Str $widget-name --> Any ) {

  # create a text input widget
  given my Gnome::Gtk3::TextView $textview .= new {

    .set-hexpand(True);
    .set-size-request( 1, $!question.height // 50);
    .set-wrap-mode(GTK_WRAP_WORD);
    .set-border-width(1);
    .register-signal( self, 'check-on-focus-change', 'focus-out-event');
  }

  self.add-class( $textview, 'QATextView');

  $textview
}

#-------------------------------------------------------------------------------
method get-value ( $textview --> Any ) {
  my Gnome::Gtk3::TextBuffer $textbuffer .= new(
    :native-object($textview.get-buffer)
  );

  my Gnome::Gtk3::TextIter $start = $textbuffer.get-start-iter;
  my Gnome::Gtk3::TextIter $end = $textbuffer.get-end-iter;
  $textbuffer.get-text( $start, $end, True)
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $textview, $text ) {
  if ?$text {
    my Gnome::Gtk3::TextBuffer $textbuffer .= new(
      :native-object($textview.get-buffer)
    );

    $textbuffer.set-text($text);
  }
}

#-------------------------------------------------------------------------------
method check-value ( Str $input --> Str ) {
  my Str $message;
  my Int $nw = $input.comb(/\w+/).elems;
  if ?$!question.minimum and $nw < $!question.minimum {
    $message = "Minimum number of words = $!question.minimum()";
  }

  elsif ?$!question.maximum and $nw > $!question.maximum {
    $message = "Maximum number of words = $!question.maximum()";
  }

  $message
}

#-------------------------------------------------------------------------------
method check-on-focus-change (
  N-GdkEventFocus $, :_widget($textview) --> Int
) {
  self.process-widget-signal( $textview, :do-check);

  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}













=finish

#-------------------------------------------------------------------------------
method check-value ( --> Any ) {
}

#-------------------------------------------------------------------------------
method !add-value ( Str $text ) {
}

#-------------------------------------------------------------------------------
method set-value (
  $data-key, $data-value, $row, Bool :$overwrite = True, Bool :$last-row
) {

#note "SV 0: set value $data-key, $data-value, $row";
  # if not repeatable, only row 0 can exist. the rest is ignored.
  return if not $!repeatable and $row > 0;

#  my Int $tb-col = self.check-toolbutton-column;

  # if $data-key is a number then only text without a combobox is shown. Text
  # is found in $data-value. If a combobox is needed then text is in text-key
  # and combobox selection in text-value.
  my Bool $need-combobox = ?$!input-category;
  my Str $text = ($data-key ~~ m/^ \d+ $/).Bool ?? $data-value !! $data-key;
#note "SV 1: $text";

  # check if there is an input field defined. if not, create input field.
  # otherwise get object from grid
  my Bool $new-row;
  my Gnome::Gtk3::Entry $entry;
  if $!input-widgets[$row].defined {
    $new-row = False;
    $entry .= new(:native-object($!grid.get-child-at( 0, $row)));
  }

  else {
    $new-row = True;
    $entry .= new( :$text, :$!example, :$!tooltip, :$!visibility);

    $entry.register-signal( self, 'check-on-focus-change', 'focus-out-event');
    $!grid.grid-attach( $entry, 0, $row, 1, 1);
    $!input-widgets.push($entry);
  }

  # the text can be written only if field is empty or if overwrite is True
  $!input-widgets[$row].set-text($text)
    if ! $!input-widgets[$row].get-text or $overwrite;

  # insert and set value of a combobox
  my Gnome::Gtk3::ComboBoxText $cbt;
  if $need-combobox {
    if $new-row {
      $cbt = self.create-combobox;
      $!grid.attach-next-to( $cbt, $entry, GTK_POS_RIGHT, 1, 1);
    }

    else {
      $cbt .= new(:native-object($!grid.get-child-at( 1, $row)));
    }

    self.set-combobox-select( $cbt, $data-value.Str);
  }

  # at last the toolbutton if $!repeatable
  if $!repeatable {
    my Gnome::Gtk3::ToolButton $tb;
    if $new-row {
      $tb = self.create-toolbutton(:add($last-row));
      $!grid.attach-next-to(
        $tb, $need-combobox ?? $cbt !! $entry, GTK_POS_RIGHT, 1, 1
      );
    }

    else {

    }
  }

  self.rename-buttons;
}

#-------------------------------------------------------------------------------
method add-entry (
  Gnome::Gtk3::ToolButton :_widget($toolbutton), Int :$_handler-id
) {

  # modify this buttons icon and signal handler
  my Gnome::Gtk3::Image $image .= new;
  $image.set-from-icon-name( 'list-remove', GTK_ICON_SIZE_BUTTON);

  $toolbutton.set-icon-widget($image);
  $toolbutton.handler-disconnect($_handler-id);
  $toolbutton.register-signal( self, 'delete-entry', 'clicked');

  # create new tool button on row below the button triggering this handler
  my Gnome::Gtk3::ToolButton $tb;
  $image .= new;
  $image.set-from-icon-name( 'list-add', GTK_ICON_SIZE_BUTTON);
  $tb .= new(:icon($image));
  $tb.register-signal( self, 'add-entry', 'clicked');
  $!grid.attach-next-to( $tb, $toolbutton, GTK_POS_BOTTOM, 1, 1);

  # check if a combobox is to be drawn
  my Int $tbcol = self.check-toolbutton-column;
  my Gnome::Gtk3::ComboBoxText $cbt;
  if $tbcol == 2 {
    $cbt = self.create-combobox;
    $!grid.attach-next-to( $cbt, $tb, GTK_POS_LEFT, 1, 1);
  }

  # create new text entry to the left of the button
  my Gnome::Gtk3::Entry $entry .= new(:$!visibility);
  $!grid.attach-next-to(
    $entry, $tbcol == 2 ?? $cbt !! $tb, GTK_POS_LEFT, 1, 1
  );

  self.rename-buttons;
  $!grid.show-all;
}

#-------------------------------------------------------------------------------
method delete-entry (
  Gnome::Gtk3::ToolButton :_widget($toolbutton), Int :$_handler-id
) {

  # delete a row using the name of the toolbutton, see also rename-buttons().
  my Str $name = $toolbutton.get-name;
  $name ~~ s/ 'tb-button' //;
  my Int $row = $name.Int;
  $!grid.remove-row($row);
  self.rename-buttons;
}

#-------------------------------------------------------------------------------
# rename buttons in such a way that the row number is saved in the name.
method rename-buttons ( ) {

  my Int $tb-col = self.check-toolbutton-column;
  my Int $row = 0;
  my Gnome::Gtk3::ToolButton $toolbar-button;
  loop {
    my $ntb = $!grid.get-child-at( $tb-col, $row);
    last unless $ntb.defined;

    $toolbar-button .= new(:native-object($ntb));
    $toolbar-button.set-name("tb-button$row");
    $row++;
  }
}

#-------------------------------------------------------------------------------
# plans are to insert a combobox before entry. this means that toolbutton
# can be in column 1 or 2
method check-toolbutton-column ( --> Int ) {

  my $ntb = $!grid.get-child-at( 2, 0);
  $ntb.defined ?? 2 !! 1
}

#-------------------------------------------------------------------------------
method create-toolbutton ( Bool :$add --> Gnome::Gtk3::ToolButton ) {

  my Gnome::Gtk3::Image $image .= new;
  $image.set-from-icon-name(
    $add ?? 'list-add' !! 'list-remove', GTK_ICON_SIZE_BUTTON
  );

  my Gnome::Gtk3::ToolButton $tb .= new(:icon($image));
  $tb.register-signal(
    self, $add ?? 'add-entry' !! 'delete-entry', 'clicked'
  );

  $tb
}

#-------------------------------------------------------------------------------
method create-combobox ( Str $select = '' --> Gnome::Gtk3::ComboBoxText ) {

  my Gnome::Gtk3::ComboBoxText $cbt .= new;
  for @$!input-category -> $v {
    $cbt.append-text($v);
  }

  self.set-combobox-select( $cbt, $select);
  $cbt
}

#-------------------------------------------------------------------------------
method set-combobox-select( Gnome::Gtk3::ComboBoxText $cbt, Str $select = '' ) {

  my Int $value-index = $!input-category.first( $select, :k) // 0;
  $cbt.set-active($value-index);
}

#-------------------------------------------------------------------------------
method check-on-focus-change ( N-GdkEventFocus $event, :_widget($w) --> Int ) {

#note 'focus change';
  my Gnome::Gtk3::Entry $entry = $w;
  my Str $input = $entry.get-text;
#    $input = $kv<default> // Str unless ?$input;

  my Bool $faulty-state;
#`{{
  my Str $cb-name = ($!callback-name // '_') ~ '-sts';
  if ?$*callback-object and $*callback-object.^can($cb-name) {
    $faulty-state = $*callback-object."$cb-name"( :$input, :$kv);
  }

  else {
    $faulty-state = (?$kv<required> and !$input);
  }
}}
  $faulty-state = (?$!required and !$input);

  if $faulty-state {
    self.set-status-hint( $entry, QAStatusFail);
  }

  elsif ?$!required {
    self.set-status-hint( $entry, QAStatusOk);
    my Str ( $widget-name, $row) = $entry.get-name.split(':');
    if $!repeatable {
      #if $!... {
      #}
      $!user-data-set-part{$widget-name}[$row] = $input;
    }

    else {
      $!user-data-set-part{$widget-name} = $input;
    }
  }

  else {
    self.set-status-hint( $entry, QAStatusNormal);
  }


  # must propogate further to prevent messages when notebook page is switched
  # otherwise it would do ok to return 1.
  0
}
