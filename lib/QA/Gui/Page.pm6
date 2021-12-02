use v6;

use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Enums;

use QA::Gui::Frame;
use QA::Gui::Set;
use QA::Set;

#-------------------------------------------------------------------------------
unit class QA::Gui::Page:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
has Array $!sets = [];
has Hash $!page;
has Gnome::Gtk3::Grid $!page-grid;
has Int $!page-row;
has Bool $!description;
has Bool $.faulty-page-state;
has Hash $!user-data;

#-------------------------------------------------------------------------------
submethod BUILD (
  Hash :$!page, Bool :$!description = True, Hash :$!user-data
) { }

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method create-content( --> Gnome::Gtk3::ScrolledWindow ) {

  my Gnome::Gtk3::ScrolledWindow $page-window .= new;
  $!page-grid .= new;
  $!page-row = 0;
  $page-window.add($!page-grid);

  self!description if $!description;

  # display all selected sets
  for @($!page<sets>) -> Hash $set-data {
    my QA::Set $set .= new(:$set-data);
    my Str $set-name = $set-data<set-name>;

    # check if userdata exists
    $!user-data{$!page<page-name>}{$set-name} = %()
      unless $!user-data{$!page<page-name>}{$set-name} ~~ Hash;

    # display a set
    my QA::Gui::Set $gui-set .= new(
      :grid($!page-grid), :grid-row($!page-row), :$set,
      :user-data-set-part($!user-data{$!page<page-name>}{$set-name})
    );
    $!sets.push: $gui-set;
    $!page-row++;
  }

  # return the page
  $page-window.widget-set-hexpand(True);
  $page-window.widget-set-vexpand(True);
  $page-window
}

#-------------------------------------------------------------------------------
method query-page-state ( --> Bool ) {

  $!faulty-page-state = False;
  for @$!sets -> $set {

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
  with my Gnome::Gtk3::Label $page-descr .= new(:text($!page<description>)) {
    .set-line-wrap(True);
    .widget-set-halign(GTK_ALIGN_START);
    .widget-set-margin-bottom(3);
    .widget-set-margin-start(5);
  }

  $page-frame.add($page-descr);
}
