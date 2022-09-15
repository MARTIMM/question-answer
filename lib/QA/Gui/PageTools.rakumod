#TL:1:QA::Gui::PageTools:

use v6;

use Gnome::Gio::Resource;

use Gnome::Gtk3::CssProvider;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
use Gnome::Gtk3::Dialog;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Stack;
use Gnome::Gtk3::StackSwitcher;
use Gnome::Gtk3::Notebook;

use QA::Questionaire;
use QA::Types;

use QA::Gui::Statusbar;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;

#-------------------------------------------------------------------------------
unit role QA::Gui::PageTools:auth<github:MARTIMM>;

has Gnome::Gtk3::Grid $!grid;
has Hash $!pages = %();
has QA::Questionaire $!qst;
has Str $!qst-name;

has Hash $.result-user-data;
has Hash $!user-data;
has Bool $!save-data;

has Gnome::Gtk3::Stack $!stack;

#-------------------------------------------------------------------------------
method set-grid ( $container ) {
note 'set-grid: ', $container.^name;

  # Set the contents of the grid depending of the type of container
  given $container.^name {

    when / PageSimple || PageNotebook / {
      $!grid = $container.dialog-content;
    }

    when / PageStack / {
      $!grid = $container.dialog-content;

      # create the stack and add pages to it
      $!stack .= new;
      $!grid.attach( $!stack, 0, 0, 1, 1);

      my Gnome::Gtk3::StackSwitcher $stack-switcher .= new;
      $stack-switcher.set-stack($!stack);
      $!grid.attach( $stack-switcher, 0, 1, 1, 1);
    }

    when / PageAssistant / {
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
    when / PageSimple / {
      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $!qst.clone;
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

    when / PageStack / {
      # select content pages only
      my $pages := $!qst.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $!stack.add-titled(
            $page.create-content, $page-data<page-name>, $page-data<title>
          );
        }
      }
    }

    when / PageNotebook / {
      # create the notebook and add pages to it
      my Gnome::Gtk3::Notebook $notebook .= new;
      $!grid.attach( $notebook, 0, 0, 1, 1);

      # select content pages only
      my $pages := $!qst.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $notebook.append-page(
            $page.create-content,
            Gnome::Gtk3::Label.new(:text($page-data<title>))
          )
        }
      }
    }

    when / PageAssistant / {
    }

    # when default, it is a user container with a grid
    default {
      # find first content page. This simple sheet display takes the first page
      # marked as content only.
      my $pages := $!qst.clone;
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
#TM:1:add-button
=begin pod
=head2 add-button

For dialog types it is possible to add some buttons to the dialog

  method add-button (
    Str $widget-name, GtkResponseType $response-type
  )

=item $widget-name;
=item $response-type;

=end pod
method add-button (
  Str $widget-name, $response-type where .^name eq 'GtkResponseType',
  Bool :$default = False
) {
#note "add button $widget-name";

  # it is possible that button is undefined
  my Gnome::Gtk3::Button $button = self.create-button($widget-name);
  with $button {
    my Hash $button-map = $!qst.button-map // %();
    if ? $button-map{$widget-name}<default> {
      .set-can-default(True);
      self.set-default-response($response-type);
    }

    self.add-action-widget( $button, $response-type);
  }
}

#-------------------------------------------------------------------------------
method create-button (
  Str $widget-name, Any :$method-object?, Str :$method-name?
  --> Gnome::Gtk3::Button
) {
  # change text of label on button when defined in the button map structure
  my Hash $button-map = $!qst.button-map // %();
  my Str $button-text = $button-map{$widget-name}<name> // $widget-name;

  # uppercase first letter of every word.
  $button-text = $button-text.split(/<[-_\s]>+/)>>.tc.join(' ');

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
  $!user-data = $user-data // $qa-types.qa-load( $!qst-name, :userdata);
}

#-------------------------------------------------------------------------------
method save-data ( ) {
  $!result-user-data = $!user-data;
  my QA::Types $qa-types .= instance;
  $qa-types.qa-save( $!qst-name, $!result-user-data, :userdata)
    if $!save-data;
}

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page( Hash $page, Bool :$description = True --> QA::Gui::Page ) {
note "\nPage: ", $page.<page-name>;
  my QA::Gui::Page $gui-page .= new(
    :$page, :$description, :$!user-data, :$!pages
  );
  $!pages{$page.<page-name>} = $gui-page;

  $gui-page
}

#-------------------------------------------------------------------------------
# hash displayer tool
method show-hash ( Hash $h is copy = Hash, Int :$i is copy ) {
  $h //= $!result-user-data;

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
      note '  ' x $i, "$k => ";
      for @($h{$k}) -> $item {
        note '  ' x $i, $item.gist;
      }
    }

    else {
      note '  ' x $i, "$k => $h{$k}";
    }
  }

  $i--;
}

#-------------------------------------------------------------------------------
#TM:1:show-qst
=begin pod
=head2 show-qst

Dialogs need some control to show the dialog and when finished need some loop mechanism to re-show the dialog and to show messages when there is some faulty input.

  method show-qst ( )

=end pod

method show-qst ( ) {

  my QA::Status $status .= instance;
  $status.clear-status;

  loop {
    given my Int $response-type = GtkResponseType(self.show-dialog) {
      when GTK_RESPONSE_DELETE_EVENT {
        self.hide;
        sleep(0.3);
        self.destroy;
        last;
      }

      when GTK_RESPONSE_OK {
        if $status.faulty-state {
          self.show-message(
            "There are still missing or wrong answers, cannot save data"
          );
        }

        else {
          self.save-data;
          self.destroy;
          last;
        }
      }

      when GTK_RESPONSE_APPLY {
        if $status.faulty-state {
          self.show-message(
            "There are still missing or wrong answers, cannot save data"
          );
        }

        else {
          self.save-data;
        }
      }

      when GTK_RESPONSE_CANCEL {
        if self.show-cancel {
          self.destroy;
          last;
        }
      }

      when GTK_RESPONSE_HELP {
        my Str $text = $!qst.button-map<help-info><message>;
        self.show-message($text) if ?$text;
      }

      default {
        die "Response type '$_' not supported";
      }
    }
  }
}

#-------------------------------------------------------------------------------
method show-message ( Str:D $message --> Int ) {
  my QA::Gui::OkMsgDialog $ok .= new(:$message);
  my $r = $ok.run;
  $ok.destroy;

  $r
}
