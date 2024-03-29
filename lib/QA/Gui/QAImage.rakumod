use v6.d;
use NativeCall;

use Gnome::Gdk3::Pixbuf;

use Gnome::Gtk4::FileChooser:api<2>;
use Gnome::Gtk4::FileChooserButton:api<2>;
use Gnome::Gtk4::FileFilter:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Image:api<2>;
#use Gnome::Gtk4::StyleContext:api<2>;

use Gnome::Gtk4::TargetEntry:api<2>;
#use Gnome::Gtk4::DragSource:api<2>;
use Gnome::Gtk4::Drag:api<2>;
use Gnome::Gtk4::DragDest:api<2>;
use Gnome::Gtk4::TargetList:api<2>;
use Gnome::Gtk4::SelectionData:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;

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

use URI::Encode;

#-------------------------------------------------------------------------------
unit class QA::Gui::QAImage;
also does QA::Gui::Value;

#-------------------------------------------------------------------------------
enum IMAGEGRID <FCHOOSER-ROW IMAGE-ROW>;

has Str $!dnd-targets;
has Gnome::Gtk4::Drag $!drag;

#-------------------------------------------------------------------------------
method create-widget ( Int() :$row --> Any ) {

  # init
  $!drag .= new;
  $!dnd-targets = $!question.options<dnd> // '';

  # We need a grid with 2 rows. one for the file chooser button
  # and one for the image. If DND, 1st row is made invisible.
  with my Gnome::Gtk4::FileFilter $filter .= new {
    .set-name('images');
    .add-mime-type('image/*');
    .add-mime-type('text/uri-list');
  }

  my Gnome::Gtk4::Grid $widget-grid .= new;
  self.add-class( $widget-grid, 'QAGrid');

  my Str $title = $!question.title;
  with my Gnome::Gtk4::FileChooserButton $fcb .= new(:$title) {
    .set-hexpand(True);
    .set-vexpand(True);
    .set-filter($filter);
    .set-border-width(2) if ?$!dnd-targets;
    .register-signal( self, 'input-change-handler', 'file-set', :$row);
    .register-signal( self, 'must-hide', 'show');
  }

  self.add-class( $fcb, 'QAFileChooserButton');
  $widget-grid.attach( $fcb, 0, FCHOOSER-ROW, 1, 1);

  my Gnome::Gtk4::Image $image .= new;
  self.add-class( $image, 'QAImage');
  $image.set-from-icon-name( 'viewimage', GTK_ICON_SIZE_DIALOG);

  # When drag and drop is requested, prepare a drag destination. Then,
  # also no file chooser button is necessary. Button is made invisible
  # on the show event
  self.setup-as-drag-destination( $image, $fcb, $widget-grid, $row);

  $widget-grid.attach( $image, 0, IMAGE-ROW, 1, 1);

  $widget-grid
}

#-------------------------------------------------------------------------------
method get-value ( $grid --> Any ) {
  my Gnome::Gtk4::FileChooserButton $fcb = $grid.get-child-at-rk( 0, 0);
  $fcb.get-filename // ''
}

#-------------------------------------------------------------------------------
method set-value ( Any:D $grid, $filename ) {
  if ?$filename {
    my Gnome::Gtk4::FileChooserButton $fcb = $grid.get-child-at-rk( 0, 0);
    $fcb.set-filename($filename);# unless ?$!question.dnd;
    self!set-image( $grid, $filename);
#    $fcb.hide if ?$!question.dnd;
  }
}

#-------------------------------------------------------------------------------
method clear-value ( Any:D $grid ) {
  my Gnome::Gtk4::FileChooserButton $fcb = $grid.get-child-at-rk(
    0, FCHOOSER-ROW
  );

  $fcb.set-filename('');
  my Gnome::Gtk4::Image $image = $grid.get-child-at-rk(
    0, IMAGE-ROW
  );

  $image.set-from-icon-name( 'viewimage', GTK_ICON_SIZE_DIALOG);
}

#-------------------------------------------------------------------------------
method input-change-handler (
  Gnome::Gtk4::FileChooserButton() :_native-object($fcb), Int() :$row
) {

  # must get the grid because the unit is a grid
  my Gnome::Gtk4::Grid $grid .= new(:native-object($fcb.get-parent));

  # repaint and store image locally
  self!set-image( $grid, $fcb.get-filename);

  # store in user data without checks
  self.process-widget-input( $grid, $fcb.get-filename, $row, :!do-check);
}

#-------------------------------------------------------------------------------
# Make widget invisible when dnd is turned on. Wait until widgets are shown
# to be able to turn it off.
method must-hide ( Gnome::Gtk4::FileChooserButton() :_native-object($fcb) ) {
  $fcb.hide if ?$!dnd-targets;
}

#-------------------------------------------------------------------------------
method !set-image ( Gnome::Gtk4::Grid $grid, Str $filename ) {

  my Int $width = $!question.width // 100;
  my Int $height = $!question.height // 100;
  my Gnome::Gdk3::Pixbuf $pb .= new( :file($filename), :$width, :$height);
  note $pb.last-error.message if $pb.last-error.is-valid;

  my Gnome::Gtk4::Image $image = $grid.get-child-at-rk( 0, IMAGE-ROW);
  $image.set-from-pixbuf($pb);
}

#-------------------------------------------------------------------------------
method setup-as-drag-destination (
  $destination-widget, Gnome::Gtk4::FileChooserButton $fcb,
  Gnome::Gtk4::Grid $widget-grid, Int() $row
) {

  my Array[N-GtkTargetEntry] $target-entries = Array[N-GtkTargetEntry].new;
  for $!dnd-targets.split(/\s* ',' \s*/) -> $target {
    $target-entries.push:  N-GtkTargetEntry.new( :$target, :flags(0), :info(0));
  }

  my Gnome::Gtk4::DragDest $destination .= new;
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
  Gnome::Gdk3::DragContext() $context, Int $x, Int $y, UInt $time,
  Gnome::Gtk4::FileChooserButton() :_native-object($destination-widget),
  Gnome::Gtk4::DragDest :$destination
  --> Bool
) {
  my Bool $status;

  my Gnome::Gdk3::Atom() $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );

  if $target-atom.name ~~ 'NONE' {
    $context.status( GDK_ACTION_NONE, $time);
    $status = False;
  }

  else {
    $!drag.highlight($destination-widget);
    $context.status( GDK_ACTION_COPY, $time);
    $status = True;
  }

  $status
}

#-------------------------------------------------------------------------------
method leave (
  N-GObject $context-no, UInt $time,
  Gnome::Gtk4::FileChooserButton() :_native-object($destination-widget),
  Gnome::Gtk4::DragDest :$destination
) {
  $!drag.unhighlight($destination-widget);
}

#-------------------------------------------------------------------------------
method drop (
  Gnome::Gdk3::DragContext() $context, Int $x, Int $y, UInt $time,
  Gnome::Gtk4::FileChooserButton() :_native-object($destination-widget),
  Gnome::Gtk4::DragDest :$destination
  --> Bool
) {
  my Gnome::Gdk3::Atom() $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );

  # ask for data. triggers drag-data-get on source. when data is received or
  # error, drag-data-received on destination is triggered
  $!drag.get-data(
    $destination-widget, $context, $target-atom, $time
  ) if ?$target-atom;

  True
}

#-------------------------------------------------------------------------------
method received (
  Gnome::Gdk3::DragContext() $context, Int $x, Int $y,
  Gnome::Gtk4::SelectionData() $selection-data, UInt $info, UInt $time,
  Gnome::Gtk4::FileChooserButton() :_native-object($destination-widget),
  Gnome::Gtk4::DragDest :$destination,
  Gnome::Gtk4::FileChooserButton :$fcb, Gnome::Gtk4::Grid :$widget-grid,
  Int() :$row
) {

  my $source-data;
  my Gnome::Gdk3::Atom() $target-atom = $destination.find-target(
    $destination-widget, $context,
    $destination.get-target-list($destination-widget)
  );

  if $target-atom.name eq 'text/uri-list' {
#CONTROL { when CX::Warn {  note .gist; .resume; } }
#CATCH { default { .message.note; .backtrace.concise.note } }

    my Gnome::Gtk4::Grid $grid .= new(:native-object($fcb.get-parent));

    $source-data = $selection-data.get-uris;
    # Replace if only one. Otherwise append all if more than one.
    if $source-data.elems == 1 {
      my Str $uri = $source-data[0];
      if $uri.IO.extension ~~ any(<jpg png jpeg svg gif>) {
        $uri ~~ s/^ 'file://' //;
        $uri = uri_decode($uri);

        $fcb.set-filename($uri);
        self!set-image( $grid, $uri);
        self.process-widget-input( $grid, $uri, $row, :!do-check);
      }
    }

    else {
      for @$source-data -> $uri is copy {
        if $uri.IO.extension ~~ any(<jpg png jpeg svg gif>) {
          $uri ~~ s/^ 'file://' //;
          $uri = uri_decode($uri);

          my ( $added-widget, $added-row) = $!gui-input-widget.append-grid-row;

          my Gnome::Gtk4::FileChooserButton() $new-fcb =
            $added-widget.get-child-at( 0, FCHOOSER-ROW);
          $new-fcb.set-filename($uri);
          self!set-image( $added-widget, $uri);
          self.process-widget-input(
            $added-widget, $uri, $added-row, :!do-check
          );
        }
      }
    }
  }
}
