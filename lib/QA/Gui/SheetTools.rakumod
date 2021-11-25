#TL:1:QA::Gui::SheetTools:

use v6;

use Gnome::Gio::Resource;

use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;

use QA::Sheet;
use QA::Types;

use QA::Gui::Statusbar;
use QA::Gui::Page;

#-------------------------------------------------------------------------------
unit role QA::Gui::SheetTools:auth<github:MARTIMM>;

has Gnome::Gtk3::Grid $!grid;
has Array $!pages = [];
has QA::Sheet $!sheet;
has Str $!sheet-name;

has Hash $.result-user-data;
has Hash $!user-data;
has Bool $!save-data;

#-------------------------------------------------------------------------------
method set-grid ( $container ) {

  given $container.^name {
    when / SheetSimple || SheetStack || SheetNotebook / {
      $!grid = $container.dialog-content;
    }

    when / SheetAssistant / {
    }

    when / Window / {
      $!grid .= new;
      $container.add($!grid);
    }
  }
}

#-------------------------------------------------------------------------------
method set-grid-content ( $pager-type, QA::Sheet $sheet --> Int ) {

note 'Pager: ', $pager-type.^name;
  given $pager-type.^name {
    when / SheetSimple / {
      my QA::Gui::Statusbar $statusbar .= new;
      $!grid.grid-attach( $statusbar, 0, 1, 1, 1);

      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!grid.attach( $page.create-content, 0, 0, 1, 1);

          last;
        }
      }
    }

    when / SheetStack / {
    }

    when / SheetNotebook / {
    }

    when / SheetAssistant / {
    }

    # when default, it is a user container with a grid
    default {
      my QA::Gui::Statusbar $statusbar .= new;
      $!grid.grid-attach( $statusbar, 0, 1, 1, 1);

      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!grid.attach( $page.create-content, 0, 0, 1, 1);

          last;
        }
      }
    }
  }
}

#-------------------------------------------------------------------------------
method create-button (
  Str $widget-name, Any :$method-object?, Str :$method-name?
  --> Gnome::Gtk3::Button
) {
  # change text of label on button when defined in the button map structure
  my Hash $button-map = $!sheet.button-map // %();
  my Str $button-text = $button-map{$widget-name} // $widget-name;

  with my Gnome::Gtk3::Button $button .= new {
    # change some other parameters
    .set-name($widget-name);
    .set-label($button-text.tc);

    # and register a signal if user object and method name are provided
    .register-signal( $method-object, $method-name, 'clicked')
      if ?$method-object and ?$method-name;
  }

  $button
}

#-------------------------------------------------------------------------------
method set-style ( Str:D $class-name ) {
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

  $context.add-class($class-name);
}

#-------------------------------------------------------------------------------
method load-user-data ( Hash $user-data ) {
  my QA::Types $qa-types .= instance;
  $!user-data = $user-data //
                $qa-types.qa-load( $!sheet-name, :userdata) //
                %();
}

#-------------------------------------------------------------------------------
method save-data ( ) {
  $!result-user-data = $!user-data;
  my QA::Types $qa-types .= instance;
  $qa-types.qa-save( $!sheet-name, $!result-user-data, :userdata)
    if $!save-data;
}

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page( Hash $page, Bool :$description = True --> QA::Gui::Page ) {
  my QA::Gui::Page $gui-page .= new( :$page, :$description, :$!user-data);
  $!pages.push: $gui-page;

  $gui-page
}
