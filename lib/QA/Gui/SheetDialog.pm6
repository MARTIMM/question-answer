#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Enums;
use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Notebook;
use Gnome::Gtk3::Stack;
use Gnome::Gtk3::StackSwitcher;
use Gnome::Gtk3::Assistant;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
use Gnome::Gtk3::Builder;

use QA::Set;
use QA::Sheet;
use QA::Types;

use QA::Gui::Set;
use QA::Gui::Question;
use QA::Gui::Dialog;
use QA::Gui::Frame;
use QA::Gui::Statusbar;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::SheetDialog

This module shows a dialog wherein sets of questions are displayed. Several ways to display the sheet are available
=end pod

unit class QA::Gui::SheetDialog:auth<github:MARTIMM>;
also is QA::Gui::Dialog;

#-------------------------------------------------------------------------------
has QA::Sheet $!sheet;
has Str $!sheet-name;
has Hash $!user-data;
has Hash $.result-user-data;
has Array $!sets = [];
has Bool $.faulty-state;
has Bool $!show-cancel-warning;
has Bool $!save-data;

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

  my Gnome::Gtk3::Grid $grid = self.dialog-content;

  given $!sheet.display {
    when QADialog {

      my Gnome::Gtk3::ScrolledWindow $page-window = self!create-page(
        $!sheet.get-page(0), :!title, :!description
      );
      $page-window.widget-set-hexpand(True);
      $page-window.widget-set-vexpand(True);

      $grid.grid-attach( $page-window, 0, 0, 1, 1);


      # add some buttons specific for this notebook
      self!create-button(
        'cancel', 'cancel-dialog', GTK_RESPONSE_CANCEL, :default
      );
      self!create-button( 'finish', 'finish-dialog', GTK_RESPONSE_OK);

      self.register-signal( self, 'dialog-response', 'response');
      my QA::Gui::Statusbar $statusbar .= instance;
      $grid.grid-attach( $statusbar, 0, 1, 1, 1);
    }

    when QANoteBook {
      # create a notebook and place on the grid of the dialog
      my Gnome::Gtk3::Notebook $notebook .= new;
      $notebook.widget-set-hexpand(True);
      $notebook.widget-set-vexpand(True);
      $grid.grid-attach( $notebook, 0, 0, 1, 1);

      # for each page ...
      my $pages := $!sheet.clone;
      for $pages -> Hash $page {

        # create page
        my Gnome::Gtk3::ScrolledWindow $page-window = self!create-page(
          $page, :!title, :description
        );

        # add the created page to the notebook
        $notebook.append-page(
          $page-window, Gnome::Gtk3::Label.new(:text($page<title>))
        );
      }

      # add some buttons specific for this notebook
      self!create-button(
        'cancel', 'cancel-dialog', GTK_RESPONSE_CANCEL, :default
      );
      self!create-button( 'finish', 'finish-dialog', GTK_RESPONSE_OK);

      self.register-signal( self, 'dialog-response', 'response');
      my QA::Gui::Statusbar $statusbar .= instance;
      $grid.grid-attach( $statusbar, 0, 1, 1, 1);
    }

    when QAStack {
      my Gnome::Gtk3::Stack $stack .= new;
      $stack.widget-set-hexpand(True);
      $stack.widget-set-vexpand(True);
      $grid.grid-attach( $stack, 0, 0, 1, 1);

      # for each page ...
      my $pages := $!sheet.clone;
      for $pages -> Hash $page {

        # create page
        my Gnome::Gtk3::ScrolledWindow $page-window = self!create-page(
          $page, :!title, :description
        );

        # add the created page to the notebook
        $stack.add-titled( $page-window, $page<name>, $page<title>);
      }

      my Gnome::Gtk3::StackSwitcher $stack-switcher .= new;
      $stack-switcher.set-stack($stack);
      $grid.grid-attach( $stack-switcher, 0, 1, 1, 1);

      # add some buttons specific for this notebook
      self!create-button(
        'cancel', 'cancel-dialog', GTK_RESPONSE_CANCEL, :default
      );
      self!create-button( 'finish', 'finish-dialog', GTK_RESPONSE_OK);

      self.register-signal( self, 'dialog-response', 'response');
      my QA::Gui::Statusbar $statusbar .= instance;
      $grid.grid-attach( $statusbar, 0, 2, 1, 1);
    }

    when QAAssistant {
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
  my Gnome::Gtk3::StyleContext $style-context .= new;
  $style-context.add_provider_for_screen(
    Gnome::Gdk3::Screen.new, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );
}

#-------------------------------------------------------------------------------
method !create-button (
  Str $widget-name, Str $method-name, GtkResponseType $response-type,
  Bool :$default = False
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
    self.set-default-response($response-type);
  }

#  $button.register-signal( self, $method-name, 'clicked');
  self.add-action-widget( $button, $response-type);
}

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page(
  Hash $page, Bool :$title = True, Bool :$description = True
  --> Gnome::Gtk3::ScrolledWindow
) {

  my Gnome::Gtk3::ScrolledWindow $page-window .= new;
  my Gnome::Gtk3::Grid $page-grid .= new;
  $page-window.container-add($page-grid);
#  $page-grid.set-border-width(5);
  my Int $page-row = 0;

  if $description {
    # place page title in frame if wished
    my QA::Gui::Frame $page-frame .= new(
      :label($title ?? $page<title> !! '')
    );
    $page-grid.grid-attach( $page-frame, 0, $page-row++, 2, 1);

    # place description as text in this frame
    given my Gnome::Gtk3::Label $page-descr .= new(:text($page<description>)) {
      .set-line-wrap(True);
      #.set-max-width-chars(60);
      #.set-justify(GTK_JUSTIFY_LEFT);
      .widget-set-halign(GTK_ALIGN_START);
      .widget-set-margin-bottom(3);
      .widget-set-margin-start(5);
    }
    $page-frame.container-add($page-descr);
  }

  # display all selected sets
  for @($page<sets>) -> Hash $set-data {
    # set data consists of a category name and set name. Both are needed
    # to get the set data we need.
    my Str $category-name = $set-data<category>;
    my Str $set-name = $set-data<set>;

    # check if userdata exists
    $!user-data{$page<name>}{$category-name}{$set-name} = %()
      unless $!user-data{$page<name>}{$category-name}{$set-name} ~~ Hash;

    # display a set
    my QA::Gui::Set $set .= new(
      :grid($page-grid), :grid-row($page-row), :$category-name, :$set-name,
      :user-data-set-part($!user-data{$page<name>}{$category-name}{$set-name})
    );
    $!sets.push: $set;
    $page-row++;
  }

  # return the page
  $page-window
}

#-------------------------------------------------------------------------------
method query-state ( ) {

  $!faulty-state = False;
  for @$!sets -> $set {

    # this question is not ok when True
    if $set.query-state {
      $!faulty-state = True;
      last;
    }
  }
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
method dialog-response (
  int32 $response, QA::Gui::SheetDialog :_widget($dialog)
) {
#Gnome::N::debug(:on);

#  note "enums: ", GtkResponseType.enums;
  note "sheet dialog response: $response, ", GtkResponseType($response);
  if GtkResponseType($response) ~~ GTK_RESPONSE_DELETE_EVENT {
    note 'Forced dialog close!';
    $dialog.widget-destroy;
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_OK {

    self.query-state;
    if $!faulty-state {
      my QA::Gui::OkMsgDialog $yn .= new(
        :message("There are still missing or wrong answers, cannot save data")
      );

      GtkResponseType($yn.dialog-run);
      $yn.widget-destroy;
    }

    else {
      $!result-user-data = $!user-data;
      my QA::Types $qa-types .= instance;
      $qa-types.qa-save( $!sheet-name, $!result-user-data, :userdata)
        if $!save-data;
#      self.widget-destroy;
    }
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_CANCEL {

    my Bool $done = True;
    if $!show-cancel-warning {
      my QA::Gui::YNMsgDialog $yn .= new(
        :message("Are you sure to cancel?\nAll changes will be lost!")
      );

      my $r = GtkResponseType($yn.dialog-run);
      $yn.widget-destroy;
      $done = ( $r ~~ GTK_RESPONSE_YES );
    }

    self.widget-destroy if $done;
  }

#Gnome::N::debug(:off);
}
