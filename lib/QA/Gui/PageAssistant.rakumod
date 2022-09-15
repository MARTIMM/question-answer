use v6.d;Page

use QA::Set;
use QA::Questionaire;
use QA::Types;

#use QA::Gui::Dialog;
use QA::Gui::Page;
#use QA::Gui::YNMsgDialog;
#use QA::Gui::OkMsgDialog;
#use QA::Gui::Statusbar;

#use Gnome::N::X;
#Gnome::N::debug(:on);

use Gnome::N::GlibToRakuTypes;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Enums;
#use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Assistant;
use Gnome::Gtk3::ScrolledWindow;
#use Gnome::Gtk3::Notebook;
#use Gnome::Gtk3::Grid;
#use Gnome::Gtk3::Label;
#use Gnome::Gtk3::Button;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageAssistant

=end pod

unit class QA::Gui::PageAssistant:auth<github:MARTIMM>:ver<0.1.0>;
also is Gnome::Gtk3::Assistant;

#-------------------------------------------------------------------------------
has QA::Questionaire $!qst;
has Str $!qst-name;
has Hash $!user-data;
has Hash $.result-user-data;
has Array $!sets = [];
has Array $!pages = [];
has Bool $.faulty-state;
has Bool $!show-cancel-warning;
has Bool $!save-data;
#has Int $!response;
#has Gnome::Gtk3::Notebook $!notebook;
#has Gnome::Gtk3::Grid $!grid;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk3::Assistant class process the options
  self.bless( :GtkAssistant, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True
) {


  my QA::Types $qa-types .= instance;
note "ass: $!qst-name, $qa-types.list-dirs()";

  $!user-data = $user-data //
                $qa-types.qa-load( $!qst-name, :userdata) //
                %();

  $!qst .= new(:$!qst-name);

  self!set-style;

  # select content pages only
  my $pages := $!qst.clone;
  for $pages -> Hash $page-data {
note "\npd: $page-data";
    if $page-data<page-type> ~~ QAContent {
      my QA::Gui::Page $page = self!create-page( $page-data, :!description);
      my Gnome::Gtk3::ScrolledWindow $page-window = $page.create-content;
      self.append-page($page-window);
#TODO add type in question
      self.set-page-type( $page-window, GTK_ASSISTANT_PAGE_CONTENT);
      self.set-page-title( $page-window, $page-data<title>);
    }
  }

  self.register-signal( self, 'exit-assistant', 'destroy');
  self.show-all;
}

#-------------------------------------------------------------------------------
method !set-style ( ) {
  # load the gtk resource file and register resource to make data global to app
  my Gnome::Gio::Resource $r .= new(
    :load(%?RESOURCES<g-resources/QAManager.gresource>.Str)
  );
  $r.register;

#TODO id needed?
  my Str $application-id = '/io/github/martimm/qa';

  # read the style definitions into the css provider and style context
  my Gnome::Gtk3::CssProvider $css-provider .= new;
  $css-provider.load-from-resource(
    $application-id ~ '/resources/g-resources/QAManager-style.css'
  );
  my Gnome::Gtk3::StyleContext $context .= new;
  $context.add-provider-for-screen(
    Gnome::Gdk3::Screen.new, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $context.add-class('QAPageAssistant');
}

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page( Hash $page, Bool :$description = True --> QA::Gui::Page ) {
  my QA::Gui::Page $gui-page .= new( :$page, :$description, :$!user-data);
  $!pages.push: $gui-page;

  $gui-page
}

#-------------------------------------------------------------------------------
method exit-assistant ( ) {
  Gnome::Gtk3::Main.new.gtk-main-quit;
}

#`{{
#-------------------------------------------------------------------------------
method show-qst ( --> Int ) {

  self.show-all;

#  while $!faulty-state {
#    $!response = self.show-dialog;
#  }

#  $!response
  0
}
}}
