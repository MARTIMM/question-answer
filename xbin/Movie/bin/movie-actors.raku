#!/usr/bin/env raku

use v6.d;
use lib 'xbin/Movie/lib';

#use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::Main:api<2>;
#use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;

#use QA::Gui::SheetDialog;
#use QA::Gui::Frame;
#use QA::Gui::Value;
use QA::Types;
#use QA::Question;

use Movie::Handlers;

#use Gnome::N::X;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
# set a few values before initializing
enum DE <SET SHEET UDATA>;
my @dirs = <xbin/Movie/Sets xbin/Movie/Sheets xbin/Movie/MovieData>;
for @dirs -> $d {
  mkdir $d, 0o700 unless $d.IO.e;
}

my Movie::Handlers $movie-handlers .= new;
given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata(@dirs[UDATA]);
  .cfgloc-sheet(@dirs[SHEET]);
  .cfgloc-set(@dirs[SET]);
#  .set-check-handler( 'check-exclam', $movie-handlers, 'check-char', :char<!>);
#  .set-action-handler( 'show-select1',$movie-handlers , 'fieldtype-action1');
#  .set-action-handler( 'show-select2', $movie-handlers, 'fieldtype-action2', :opt1<opt1>);
}

#-------------------------------------------------------------------------------
# data structure
#TODO make application window
given my Gnome::Gtk4::Window $top-window .= new {
  .set-title('Sheet Dialog Test');
  .register-signal( $movie-handlers, 'exit-app', 'destroy');
  .set-size-request( 300, 1);
  .window-resize( 300, 1);

  my Gnome::Gtk4::Grid $grid .= new;
  .add($grid);

  my Gnome::Gtk4::Button $dialog-button .= new(:label<QANotebook>);
  $grid.attach( $dialog-button, 1, 0, 1, 1);
  $dialog-button.register-signal(
    $movie-handlers, 'show-movie-form', 'clicked'
  );

  .show-all;
}

Gnome::Gtk4::Main.new.gtk-main;
