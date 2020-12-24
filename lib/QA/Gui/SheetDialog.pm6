#tl:1:QA::Gui::SheetDialog
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gio::Resource;

use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Enums;
#use Gnome::Gtk3::ScrolledWindow;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;

use QA::Set;
use QA::Sheet;
use QA::Types;

use QA::Gui::Set;
use QA::Gui::Question;
use QA::Gui::Frame;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;

use QA::Gui::DialogDisplay;
use QA::Gui::NotebookDisplay;
use QA::Gui::StackDisplay;
use QA::Gui::AssistantDisplay;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::SheetDialog

This module shows one or more sheets depending on the way the sheets are displayed. There are four ways to display sheets; using a dialog, a notebook, stack or an assistant.
=end pod

unit class QA::Gui::SheetDialog:auth<github:MARTIMM>;

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

has QA::Gui::DialogDisplay $!dialog-display;
has QA::Gui::NotebookDisplay $!notebook-display;
has QA::Gui::StackDisplay $!stack-display;
has QA::Gui::AssistantDisplay $!assistant-display;

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

  given $!sheet.display {
    when QADialog {
      $!dialog-display .= new(
        :sheet-dialog(self), :width($!sheet.width), :height($!sheet.height),
      );

      # find first content page
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          $!dialog-display.add-page(
            self!create-page( $page-data, :!description)
          );

          last;
        }
      }
    }

    when QANotebook {
      $!notebook-display .= new(
        :sheet-dialog(self), :width($!sheet.width), :height($!sheet.height),
      );

      # select content pages
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          $!notebook-display.add-page(
            self!create-page( $page-data, :description),
            :title($page-data<title>)
          );
        }
      }
    }

    when QAStack {
      $!stack-display .= new(
        :sheet-dialog(self), :width($!sheet.width), :height($!sheet.height),
      );

      # select content pages
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          $!stack-display.add-page(
            self!create-page( $page-data, :description),
            :title($page-data<title>), :name($page-data<name>)
          );
        }
      }
    }

    when QAAssistant {
      $!assistant-display .= new(
        :sheet-dialog(self), :width($!sheet.width), :height($!sheet.height),
      );

      # select all type of pages
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        $!assistant-display.add-page(
          self!create-page( $page-data, :description),
          :title($page-data<title>), :page-type($page-data<page-type>)
        );
      }

      $!assistant-display.show-all;
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

#`{{
#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page(
  Hash $page, Bool :$description = True
  --> Gnome::Gtk3::ScrolledWindow
) {

  my Gnome::Gtk3::ScrolledWindow $page-window .= new;
  my Gnome::Gtk3::Grid $page-grid .= new;
  $page-window.container-add($page-grid);
  my Int $page-row = 0;

  if $description {
    # no page title in frame
    my QA::Gui::Frame $page-frame .= new(:label(''));
    $page-grid.grid-attach( $page-frame, 0, $page-row++, 2, 1);

    # place description as text in this frame
    given my Gnome::Gtk3::Label $page-descr .= new(:text($page<description>)) {
      .set-line-wrap(True);
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
  $page-window.widget-set-hexpand(True);
  $page-window.widget-set-vexpand(True);
  $page-window
}
}}

#-------------------------------------------------------------------------------
method query-state ( ) {

  $!faulty-state = False;
  for @$!pages -> $page {

    # this question is not ok when True
    if $page.query-page-state {
      $!faulty-state = True;
      last;
    }
  }
}

#-------------------------------------------------------------------------------
method show-dialog ( --> Int ) {
  given $!sheet.display {
    when QADialog {
      $!dialog-display.show-dialog;
    }

    when QANotebook {
      $!notebook-display.show-dialog;
    }

    when QAStack {
      $!stack-display.show-dialog;
    }

    when QAAssistant {
#      $!assistant-display.show-all;
#      GTK_RESPONSE_OK
    }
  }
}

#-------------------------------------------------------------------------------
method widget-destroy ( ) {
  given $!sheet.display {
    when QADialog {
      $!dialog-display.widget-destroy;
    }

    when QANotebook {
      $!notebook-display.widget-destroy;
    }

    when QAStack {
      $!stack-display.widget-destroy;
    }

    when QAAssistant {
#      $!assistant-display.widget-destroy;
    }
  }
}

#-------------------------------------------------------------------------------
#--[ Signal Handlers ]----------------------------------------------------------
#-------------------------------------------------------------------------------
# this handler is used by three modules; QA::Gui::DialogDisplay,
# QA::Gui::NotebookDisplay and QA::Gui::StackDisplay. This is possible because
# all three are based on a Gnome::Gtk3::Dialog. The signal used is 'response'.
method dialog-response ( gint $response, QA::Gui::Dialog :_widget($dialog) ) {
#Gnome::N::debug(:on);

#note "enums: ", GtkResponseType.enums;
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
      self.save-data;

      # must hide instead of destroy, otherwise the return status
      # is set to GTK_RESPONSE_NONE
      $dialog.widget-hide;
    }
  }

  elsif GtkResponseType($response) ~~ GTK_RESPONSE_CANCEL {
    self.widget-destroy if self.show-cancel;
  }

#Gnome::N::debug(:off);
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {

  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.dialog-run);
    $yn.widget-destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }
note "done = $done";
  $done
}

#-------------------------------------------------------------------------------
method save-data ( ) {
  $!result-user-data = $!user-data;
  my QA::Types $qa-types .= instance;
  $qa-types.qa-save( $!sheet-name, $!result-user-data, :userdata)
    if $!save-data;
}
