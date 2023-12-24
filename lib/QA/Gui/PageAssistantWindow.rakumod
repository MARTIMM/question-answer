use v6.d;

use QA::Set;
use QA::Questionnaire;
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

use Gnome::Gtk4::Main:api<2>;
use Gnome::Gtk4::T-Enums:api<2>;
#use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::Assistant:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
#use Gnome::Gtk4::Notebook:api<2>;
#use Gnome::Gtk4::Grid:api<2>;
#use Gnome::Gtk4::Label:api<2>;
#use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::StyleProvider:api<2>;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageAssistant

=end pod

unit class QA::Gui::PageAssistant:auth<github:MARTIMM>;
also is Gnome::Gtk4::Assistant;

#-------------------------------------------------------------------------------
has QA::Questionnaire $!qst;
has Str $!qst-name;
has Hash $!user-data;
has Hash $.result-user-data;
has Array $!sets = [];
has Array $!pages = [];
has Bool $.faulty-state;
has Bool $!show-cancel-warning;
has Bool $!save-data;
#has Int $!response;
#has Gnome::Gtk4::Notebook $!notebook;
#has Gnome::Gtk4::Grid $!grid;

#-------------------------------------------------------------------------------
submethod new ( |c ) {
  # let the Gnome::Gtk4::Assistant class process the options
  self.bless( :GtkAssistant, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Bool :$!show-cancel-warning = True, Bool :$!save-data = True
) {


  my QA::Types $qa-types .= instance;
note "ass: $!qst-name, $qa-types.list-dirs()";
  self.load-user-data;


  $!qst .= new(:$!qst-name);

  self!set-style;

  # select content pages only
  my $pages := $!qst.clone;
  for $pages -> Hash $page-data {
note "\npd: $page-data";
    if $page-data<page-type> ~~ QAContent {
      my QA::Gui::Page $page = self!create-page( $page-data, :!description);
      my Gnome::Gtk4::ScrolledWindow $page-window = $page.create-content;
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
  my Gnome::Gtk4::CssProvider $css-provider .= new;
  $css-provider.load-from-resource(
    $application-id ~ '/resources/g-resources/QAManager-style.css'
  );
  my Gnome::Gtk4::StyleContext $context .= new;
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
  Gnome::Gtk4::Main.new.gtk-main-quit;
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
