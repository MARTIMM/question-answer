use v6.d;
use NativeCall;

use Gnome::Gdk3::Pixbuf;

use Gnome::Gtk3::FileChooser;
use Gnome::Gtk3::FileChooserButton;
use Gnome::Gtk3::FileFilter;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Image;
#use Gnome::Gtk3::StyleContext;

use Gnome::Gtk3::TargetEntry;
#use Gnome::Gtk3::DragSource;
use Gnome::Gtk3::DragDest;
use Gnome::Gtk3::TargetList;
use Gnome::Gtk3::SelectionData;
use Gnome::Gtk3::Enums;

use Gnome::Gdk3::Events;

use Gnome::Gdk3::Atom;
use Gnome::Gdk3::DragContext;
use Gnome::Gdk3::Types;
use Gnome::Gdk3::Pixbuf;

use Gnome::GObject::Value;
use Gnome::GObject::Type;

use Gnome::N::N-GObject;

use QA::Types;
use QA::Question;
use QA::Gui::Value;

#-------------------------------------------------------------------------------
unit class QA::Gui::QAImage;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
enum IMAGEGRID <FCHOOSER-ROW IMAGE-ROW>;

has QA::Question $.question;
has Hash $.user-data-set-part;
has $!input-widget;

#-------------------------------------------------------------------------------
submethod BUILD (
  QA::Question:D :$!question, Hash:D :$!user-data-set-part,
  :$!input-widget where *.^name eq 'QA::Gui::InputWidget'
) {
#  self.initialize;

#  my Gnome::Gtk3::StyleContext $context .= new(
#    :native-object(self.get-style-context)
#  );
#  $context.add-class('QAImage');
}

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # We need a grid with 2 rows. one for the file chooser button
  # and one for the image. If DND, 1st row is made invisible.
  given my Gnome::Gtk3::FileFilter $filter .= new {
    .set-name('images');
#    .add-mime-type('image/x-icon');
#    .add-mime-type('image/jpeg');
#    .add-mime-type('image/png');
#    .add-mime-type('image/gif');
#    .add-mime-type('image/svg+xml');
    .add-mime-type('image/*');
    .add-mime-type('text/uri-list');
  }

  my Gnome::Gtk3::Grid $widget-grid .= new;
  self.add-class( $widget-grid, 'QAGrid');

  my Str $title = $!question.title;
  given my Gnome::Gtk3::FileChooserButton $fcb .= new(:$title) {
    .set-hexpand(True);
    .set-vexpand(True);
    .set_filter($filter);
    .set-border-width(2) if $!question.dnd;
    .register-signal( self, 'input-change-handler', 'file-set', :$row);
    .register-signal( self, 'must-hide', 'show', :dnd($!question.dnd));
  }

  self.add-class( $fcb, 'QAFileChooserButton');
  $widget-grid.grid-attach( $fcb, 0, FCHOOSER-ROW, 1, 1);

  my Gnome::Gtk3::Image $image .= new;
  self.add-class( $image, 'QAImage');
  $image.set-from-icon-name( 'viewimage', GTK_ICON_SIZE_DIALOG);

  # When drag and drop is requested, prepare a drag destination. Then,
  # also no file chooser button is necessary. Button is made invisible
  # on the show event
  self.setup-as-drag-destination(
     $image, $!question.dnd, $fcb, $widget-grid, $row
  ) if ?$!question.dnd;

  $widget-grid.grid-attach( $image, 0, IMAGE-ROW, 1, 1);

#note "DND Target: ", $!question.dnd//'-';

  $widget-grid
}

#-------------------------------------------------------------------------------
method get-value ( $grid --> Any ) {
  my Gnome::Gtk3::FileChooserButton $fcb = $grid.get-child-at-rk( 0, 0);
#  my $filename = $fcb.get-filename // '';
#note "F: $filename";
#  $filename
  $fcb.get-filename // ''
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $grid, $filename ) {
  if ?$filename {
    my Gnome::Gtk3::FileChooserButton $fcb = $grid.get-child-at-rk( 0, 0);
    $fcb.set-filename($filename);# unless ?$!question.dnd;
    self!set-image( $grid, $filename);
#    $fcb.hide if ?$!question.dnd;
  }
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $grid ) {
  my Gnome::Gtk3::FileChooserButton $fcb = $grid.get-child-at-rk(
    0, FCHOOSER-ROW
  );

note "clear value: $grid.raku(), $fcb.raku()";
  $fcb.set-filename('');
  my Gnome::Gtk3::Image $image = $grid.get-child-at-rk(
    0, IMAGE-ROW
  );

note "clear value: image.raku()";
  $image.set-from-icon-name( 'viewimage', GTK_ICON_SIZE_DIALOG);
}

#-------------------------------------------------------------------------------
method input-change-handler (
  Gnome::Gtk3::FileChooserButton :_widget($fcb), Int() :$row
) {

  # must get the grid because the unit is a grid
  my Gnome::Gtk3::Grid $grid .= new(:native-object($fcb.get-parent));
note "$fcb.get-name(), $grid.get-name()";
#  my ( $n, $row ) = $grid.get-name.split(':');
#  $row .= Int;

  # repaint and store image locally
  self!set-image( $grid, $fcb.get-filename);

note "selected; $row, $fcb.get-filename()";
  # store in user data without checks
  self.process-widget-input( $grid, $fcb.get-filename, $row, :!do-check);
}

#-------------------------------------------------------------------------------
# Make widget invisible when dnd is turned on. Wait until widgets are shown
# to be able to turn it off.
method must-hide ( Gnome::Gtk3::FileChooserButton :_widget($fcb), Str :$dnd ) {
  $fcb.hide if ?$dnd;
}

#-------------------------------------------------------------------------------
method !set-image ( Gnome::Gtk3::Grid $grid, Str $filename ) {

  my Int $width = $!question.width // 100;
  my Int $height = $!question.height // 100;
  my Gnome::Gdk3::Pixbuf $pb .= new( :file($filename), :$width, :$height);
  note $pb.last-error.message if $pb.last-error.is-valid;

  my Gnome::Gtk3::Image $image = $grid.get-child-at-rk( 0, IMAGE-ROW);
  $image.set-from-pixbuf($pb);
note "$?LINE, $filename, $width, $height";

#  my Gnome::GObject::Value $gv .= new(:init(G_TYPE_STRING));
#  $image.get-property( 'file', $gv);
#  $gv.set-string($filename);
#note 'image set: ', $gv.get-string;

#  $image.set-name($filename);

#note $?LINE;
#  $image.set-data(
#    'image-filename', nativecast( Pointer, CArray[Str].new($filename))
#  );
#note $?LINE;
}

#-------------------------------------------------------------------------------
method setup-as-drag-destination (
  $destination-widget, Str $target-list, Gnome::Gtk3::FileChooserButton $fcb,
  Gnome::Gtk3::Grid $widget-grid, Int() $row
) {

  my Array[N-GtkTargetEntry] $target-entries = Array[N-GtkTargetEntry].new;
  for $target-list.split(/\s* ',' \s*/) -> $target {
    $target-entries.push:  N-GtkTargetEntry.new( :$target, :flags(0), :info(0));
  }

  my Gnome::Gtk3::DragDest $destination .= new;
  $destination.set(
    $destination-widget, GTK_DEST_DEFAULT_NONE, $target-entries, GDK_ACTION_COPY
  );

  $destination-widget.register-signal(
    self, 'motion', 'drag-motion', :$destination
  );

  $destination-widget.register-signal(
    self, 'leave', 'drag-leave', :$destination
  );

  $destination-widget.register-signal(
    self, 'drop', 'drag-drop', :$destination
  );

  $destination-widget.register-signal(
    self, 'received', 'drag-data-received', :$fcb, :$destination,
    :$widget-grid, :$row
  );
}

#-------------------------------------------------------------------------------
method motion (
  N-GObject $context-no, Int $x, Int $y, UInt $time,
  :_widget($destination-widget), Gnome::Gtk3::DragDest :$destination
  --> Bool
) {
#note "\ndst motion: $x, $y, $time";
  my Bool $status;

  my Gnome::Gdk3::DragContext $context .= new(:native-object($context-no));
  my Gnome::Gdk3::Atom $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );

#note $?LINE, ', Target match: ', $target-atom.name;

  if $target-atom.name ~~ 'NONE' {
    $context.status( GDK_ACTION_NONE, $time);
    $status = False;
  }

  else {
    $destination.highlight($destination-widget);
    $context.status( GDK_ACTION_COPY, $time);
    $status = True;
  }

  $status
}

#-------------------------------------------------------------------------------
method leave (
  N-GObject $context-no, UInt $time,
  :_widget($destination-widget), Gnome::Gtk3::DragDest :$destination
) {
#note "\ndst leave: $time";
  $destination.unhighlight($destination-widget);
}

#-------------------------------------------------------------------------------
method drop (
  N-GObject $context-no, Int $x, Int $y, UInt $time,
  :_widget($destination-widget), Gnome::Gtk3::DragDest :$destination
  --> Bool
) {
note "\ndst drop: $x, $y, $time";

  my Gnome::Gdk3::DragContext $context .= new(:native-object($context-no));
  my Gnome::Gdk3::Atom $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );

#note $?LINE, ', Target match: ', (?$target-atom ?? $target-atom.name !! 'NONE');

  # ask for data. triggers drag-data-get on source. when data is received or
  # error, drag-data-received on destination is triggered
  $destination.get-data(
    $destination-widget, $context-no, $target-atom, $time
  ) if ?$target-atom;

  True
}

#-------------------------------------------------------------------------------
method received (
  N-GObject $context-no, Int $x, Int $y,
  N-GObject $selection-data-no, UInt $info, UInt $time,
  :_widget($destination-widget), Gnome::Gtk3::DragDest :$destination,
  Gnome::Gtk3::FileChooserButton :$fcb is copy, Gnome::Gtk3::Grid :$widget-grid,
  Int() :$row
) {
note "\ndst received:, $x, $y, $info, $time";
  my Gnome::Gtk3::SelectionData $selection-data .= new(
    :native-object($selection-data-no)
  );

  my $source-data;
  my Gnome::Gdk3::DragContext $context .= new(:native-object($context-no));

  my Gnome::Gdk3::Atom $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );
#note $?LINE, ', Target match: ', (?$target-atom ?? $target-atom.name !! 'NONE');

  if $target-atom.name eq 'text/uri-list' {
CONTROL { when CX::Warn {  note .gist; .resume; } }
#CATCH { default { .message.note; .backtrace.concise.note } }
    # only first image is replaced, rest is added to the end.
#    my Bool $append = False;
#    my ( $n, $row );

    my Gnome::Gtk3::Grid $grid .= new(:native-object($fcb.get-parent));

    $source-data = $selection-data.get-uris;
    # Replace if only one. Otherwise append all if more than one.
    if $source-data.elems == 1 {
      my Str $uri = $source-data[0];
      if $uri.IO.extension ~~ any(<jpg png jpeg svg gif>) {
        $uri ~~ s/^ 'file://' //;
        $uri ~~ s:g/'%20'/ /;

        $fcb.set-filename($uri);
        self!set-image( $grid, $uri);
        self.process-widget-input( $grid, $uri, $row, :!do-check);
      }
    }

    else {
      for @$source-data -> $uri is copy {
note "$?LINE, $uri";
        if $uri.IO.extension ~~ any(<jpg png jpeg svg gif>) {
          $uri ~~ s/^ 'file://' //;
          $uri ~~ s:g/'%20'/ /;

          my ( $added-widget, $added-row) = $!input-widget.append-grid-row;

          $fcb = $added-widget.get-child-at-rk( 0, FCHOOSER-ROW);
          $fcb.set-filename($uri);
          self!set-image( $added-widget, $uri);
          self.process-widget-input(
            $added-widget, $uri, $added-row, :!do-check
          );
        }
      }
    }
#`{{
#note $?LINE, ', ', $source-data.elems, ', ', $source-data;
    for @$source-data -> $uri is copy {
note "$?LINE, $uri";
      if $uri.IO.extension ~~ any(<jpg png jpeg svg gif>) {
        $uri ~~ s/^ 'file://' //;
        $uri ~~ s:g/'%20'/ /;

        my Gnome::Gtk3::Grid $grid .= new(:native-object($fcb.get-parent));
note "$?LINE, $fcb.is-valid(), $grid.is-valid()";

#        if $append {
          # All entries from list are appended
#          $row = self.add-new-row;
#note "$?LINE, $grid.get-name()";
#          my Gnome::Gtk3::Grid $widget-grid = $grid.get-child-at-rk( 0, $row+1);
#note "$?LINE, $widget-grid.get-name()";
#          $fcb = $widget-grid.get-child-at-rk( 0, 0);
#        }
#`{{
        else {
          # first image of list will replace current entry
          $append = True;
note "$?LINE, {$row//'-'}, $grid.get-name()";

          # must get the grid because the unit is a grid
          ( $n, $row ) = $grid.get-name.split(':');
          $row .= Int;
#note "$?LINE, {$row//'-'}";
        }
#note "$?LINE, $row";
}}

        # repaint and store image locally
        #self!set-image( $grid, $fcb.get-filename);
note "$?LINE set filename $uri";
        $fcb.set-filename($uri);
note "$?LINE set done";

        self!set-image( $grid, $uri);
#        self.set-value( $grid, $uri);
#note $?LINE, ", selected; $fcb.get-filename()";
        # store in user data without checks
note "$?LINE, call widget input";
        self.process-widget-input( $grid, $uri, $row, :!do-check);
note "$?LINE, done widget input";
note "$?LINE, done widget input";

        #my Gnome::Gdk3::Pixbuf $pixbuf .= new(
        #  :file($uri), :380width, :380height, :preserve_aspect_ration
        #);
        #$destination-widget.set-from-pixbuf($pixbuf);
#        last;
      }
    }
}}
  }
}
