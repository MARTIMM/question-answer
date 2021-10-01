#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Notebook;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;

use QA::Set;
use QA::Sheet;
use QA::Types;

use QA::Gui::Dialog;
#use QA::Gui::Set;
#use QA::Gui::Question;
#use QA::Gui::Frame;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::Statusbar;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::SheetNotebook

=end pod

unit class QA::Gui::SheetNotebook:auth<github:MARTIMM>;
also is QA::Gui::Dialog;

#-------------------------------------------------------------------------------
has QA::Sheet $!sheet;
has Str $!sheet-name;
has Hash $!user-data;
has Hash $.result-user-data;
has Array $!sets = [];
has Array $!pages = [];
has Bool $.faulty-state;
has Bool $!show-cancel-warning;
has Bool $!save-data;
has Int $!response;
has Gnome::Gtk3::Notebook $!notebook;
has Gnome::Gtk3::Grid $!grid;

#-------------------------------------------------------------------------------
# initialize the Gtk Dialog
submethod new ( |c ) {
  self.bless( :GtkDialog, |c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!sheet-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True
) {

  my QA::Types $qa-types .= instance;
  $!user-data = $user-data //
                $qa-types.qa-load( $!sheet-name, :userdata) //
                %();

  $!sheet .= new(:$!sheet-name);

  self!set-style;

  # todo width and height spec must go to sets
  self.set-dialog-size( $!sheet.width, $!sheet.height)
    if ?$!sheet.width and ?$!sheet.height;

  $!grid = self.dialog-content;

  # add some buttons specific for this notebook
  self.create-button(
    'cancel', 'cancel-dialog', GTK_RESPONSE_CANCEL, :default, :dialog(self)
  );

  self.create-button(
    'finish', 'finish-dialog', GTK_RESPONSE_OK, :dialog(self)
  );

  # when buttons are pressed, this will prevent return to the caller until
  # the state of the sheet is ok. assume a faulty sheet for now.
  $!faulty-state = True;

  # catch button presses
  self.register-signal( self, 'dialog-response', 'response');
  my QA::Gui::Statusbar $statusbar .= instance;
  $!grid.attach( $statusbar, 0, 1, 1, 1);

  # create the notebook and add pages to it
  $!notebook .= new;
  $!grid.attach( $!notebook, 0, 0, 1, 1);

  # select content pages only
  my $pages := $!sheet.clone;
  for $pages -> Hash $page-data {
    if $page-data<page-type> ~~ QAContent {
      my QA::Gui::Page $page = self!create-page( $page-data, :!description);
      $!notebook.append-page(
        $page.create-content, Gnome::Gtk3::Label.new(:text($page-data<title>))
      )
    }
  }
}

#-------------------------------------------------------------------------------
method !set-style ( ) {
  # load the gtk resource file and register resource to make data global to app
  my Gnome::Gio::Resource $r .= new(
    :load(%?RESOURCES<g-resources/QAManager.gresource>.Str)
  );
  $r.register;

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

  $context.add-class('QASheetNotebook');
}

#-------------------------------------------------------------------------------
method create-button (
  Str $widget-name, Str $method-name, GtkResponseType $response-type,
  Bool :$default = False, QA::Gui::Dialog :$dialog
) {

  # change text of label on button when defined in the button map structure
  my Hash $button-map = $!sheet.button-map // %();
  my Gnome::Gtk3::Button $button .= new;
  my Str $button-text = $widget-name;
  $button-text = $button-map{$widget-name} if ?$button-map{$widget-name};

  # change some other parameters and register a signal
  $button.set-name($widget-name);
  $button.set-label($button-text.tc);
  if $default {
    $button.set-can-default(True);
    $dialog.set-default-response($response-type);
  }

  $dialog.add-action-widget( $button, $response-type);
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
method query-state ( ) {

  my Bool $faulty-state = False;
  for @$!pages -> $page {

    # this question is not ok when True
    if $page.query-page-state {
      $faulty-state = True;
      last;
    }
  }

  $!faulty-state = $faulty-state;
}

#-------------------------------------------------------------------------------
method show-sheet ( --> Int ) {

  while $!faulty-state {
    $!response = self.show-dialog;
  }

  $!response
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method dialog-response ( gint $response, QA::Gui::Dialog :_widget($dialog) ) {

  if GtkResponseType($response) ~~ GTK_RESPONSE_DELETE_EVENT {
    $!faulty-state = False;
    $!response = $response;

    $dialog.hide;
    sleep(0.3);
    $dialog.destroy;
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_OK {

    self.query-state;
    if $!faulty-state {
      my QA::Gui::OkMsgDialog $yn .= new(
        :message("There are still missing or wrong answers, cannot save data")
      );

      $yn.dialog-run;
      $yn.destroy;
    }

    else {
      self.save-data;
      $!response = $response;

      # must hide instead of destroy, otherwise the return status
      # is set to GTK_RESPONSE_NONE
      $dialog.hide;
    }
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_CANCEL {
    if self.show-cancel {
      $!response = $response;
      $!faulty-state = False;
      self.hide;
    }
  }
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {

  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\n<i><u>All changes will be lost!</u></i>")
    );

    my $r = GtkResponseType($yn.dialog-run);
    $yn.widget-destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}

#-------------------------------------------------------------------------------
method save-data ( ) {
  $!result-user-data = $!user-data;
  my QA::Types $qa-types .= instance;
  $qa-types.qa-save( $!sheet-name, $!result-user-data, :userdata)
    if $!save-data;
}
