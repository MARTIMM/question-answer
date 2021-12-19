#TL:1:QA::Gui::SheetTools:

use v6;

use Gnome::Gio::Resource;

use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Stack;
use Gnome::Gtk3::StackSwitcher;

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

has Gnome::Gtk3::Stack $!stack;

#-------------------------------------------------------------------------------
method set-grid ( $container ) {
note 'set-grid: ', $container.^name;

  given $container.^name {
    when / SheetSimple || SheetNotebook / {
      $!grid = $container.dialog-content;
    }

    when / SheetStack / {
      $!grid = $container.dialog-content;

      # create the stack and add pages to it
      $!stack .= new;
      $!grid.attach( $!stack, 0, 0, 1, 1);

      my Gnome::Gtk3::StackSwitcher $stack-switcher .= new;
      $stack-switcher.set-stack($!stack);
      $!grid.attach( $stack-switcher, 0, 1, 1, 1);
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
# grid row, column
#        0, 0   a page, stack, notebook or container. assistant is a container
#        0, 1   a statusbar
#
method set-grid-content ( $pager-type ) {

note 'Pager: ', $pager-type.^name;

  given $pager-type.^name {
    when / SheetSimple / {
      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!grid.attach( $page.create-content, 0, 0, 1, 1);

          last;
        }
      }

      my QA::Gui::Statusbar $statusbar .= new;
      $!grid.attach( $statusbar, 0, 1, 1, 1);
    }

    when / SheetStack / {
      # select content pages only
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!stack.add-titled(
            $page.create-content, $page-data<page-name>, $page-data<title>
          );
        }
      }
    }

    when / SheetNotebook / {
    }

    when / SheetAssistant / {
    }

    # when default, it is a user container with a grid
    default {
      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $!sheet.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!grid.attach( $page.create-content, 0, 0, 1, 1);

          last;
        }
      }

      my QA::Gui::Statusbar $statusbar .= new;
      $!grid.attach( $statusbar, 0, 1, 1, 1);
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

  # uppercase first letter of every word.
  $button-text = $button-text.split(/<[-_\s]>+/)>>.tc.join(' ');

note "CB: $button-map.raku, $button-text";

  my Gnome::Gtk3::Button $button;
  if ?$button-text {
    with $button .= new {
      # change some other parameters
      .set-name($widget-name);
      .set-label($button-text);

      # and register a signal if user object and method name are provided
      .register-signal( $method-object, $method-name, 'clicked')
        if ?$method-object and ?$method-name;
    }
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
  $!user-data = $user-data // $qa-types.qa-load( $!sheet-name, :userdata);
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
#  note "\npage: ", $page.raku;
  my QA::Gui::Page $gui-page .= new( :$page, :$description, :$!user-data);
  $!pages.push: $gui-page;

  $gui-page
}

#-------------------------------------------------------------------------------
# hash displayer tool
method show-hash ( Hash $h, Int :$i is copy ) {
  if $i.defined {
    $i++;
  }

  else {
    note '';
    $i = 0;
  }

  for $h.keys.sort -> $k {
    if $h{$k} ~~ Hash {
      note '  ' x $i, "$k => \{";
      self.show-hash( $h{$k}, :$i);
      note '  ' x $i, '}';
    }

    elsif $h{$k} ~~ Array {
      note '  ' x $i, "$k => $h{$k}.perl()";
    }

    else {
      note '  ' x $i, "$k => $h{$k}";
    }
  }

  $i--;
}
