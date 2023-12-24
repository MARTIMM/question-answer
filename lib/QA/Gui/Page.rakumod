use v6;

use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::Widget:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;

use QA::Gui::Frame;
use QA::Gui::Set;
use QA::Set;

#-------------------------------------------------------------------------------
unit class QA::Gui::Page:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
has Hash $.sets = %();
has Hash $!page;
has Hash $!pages; # must be provided to QA::Gui::Question
has Gnome::Gtk4::Grid $!page-grid;
has Int $!page-row;
has Bool $!description;
has Bool $.faulty-page-state;
has Hash $!user-data;

#-------------------------------------------------------------------------------
submethod BUILD (
  Hash :$!page, Bool :$!description = True, Hash :$!user-data, Hash :$!pages
) { }

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method create-content( --> Gnome::Gtk4::ScrolledWindow ) {

  $!page-grid .= new;
  $!page-row = 0;

  self!description if $!description;

  # display all selected sets
  for @($!page<sets>) -> Hash $set-data {
    my QA::Set $set .= new(:$set-data);
    my Str $set-name = $set-data<set-name>;

    # check if userdata exists
    $!user-data{$!page<page-name>}{$set-name} = %()
      unless $!user-data{$!page<page-name>}{$set-name} ~~ Hash;

    # display a set
#note 'Set: ', $set-name;
    my QA::Gui::Set $gui-set .= new(
      :grid($!page-grid), :grid-row($!page-row), :$set,
      :user-data-set-part($!user-data{$!page<page-name>}{$set-name}),
      :$!pages
    );
    $!sets{$set-name} = $gui-set;
    $!page-row++;
  }

  # return the page
  with my Gnome::Gtk4::ScrolledWindow $page-window .= new {
    .add($!page-grid);
    .widget-set-hexpand(True);
    .widget-set-vexpand(True);
  }

  $page-window
}

#-------------------------------------------------------------------------------
method query-page-state ( --> Bool ) {

  $!faulty-page-state = False;
  for $!sets.kv -> $k, $set {

    # this page is not ok when True
    if $set.query-state {
      $!faulty-page-state = True;
      last;
    }
  }

  $!faulty-page-state
}

#-------------------------------------------------------------------------------
method !description ( ) {
  # place page title in frame if wished
  my QA::Gui::Frame $page-frame .= new(:label(''));
  $!page-grid.attach( $page-frame, 0, $!page-row++, 2, 1);

  # place description as text in this frame
  with my Gnome::Gtk4::Label $page-descr .= new(:text($!page<description>)) {
    .set-line-wrap(True);
    .widget-set-halign(GTK_ALIGN_START);
    .widget-set-margin-bottom(3);
    .widget-set-margin-start(5);
  }

  $page-frame.add($page-descr);
}
