#TL:1:QA::Gui::PageTools:

use v6;

use Gnome::Gio::Resource:api<2>;
use Gnome::Glib::N-Error:api<2>;
#use Gnome::Gdk3::Pixbuf;

use Gnome::Gtk4::T-Enums:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::StyleProvider:api<2>;
use Gnome::Gtk4::Dialog:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::Stack:api<2>;
use Gnome::Gtk4::StackSwitcher:api<2>;
use Gnome::Gtk4::Notebook:api<2>;

use QA::Questionnaire;
use QA::Types;
use QA::Status;

use QA::Gui::Statusbar;
use QA::Gui::Page;
use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;

#-------------------------------------------------------------------------------
unit role QA::Gui::PageTools:auth<github:MARTIMM>;

has Gnome::Gtk4::Grid $!grid;
has Hash $!pages = %();
has QA::Questionnaire $!qst;
has Str $!qst-name;

has Hash $.result-user-data;
has Hash $.user-data;
has Bool $!save-data;
has Bool $!show-cancel-warning;
has $!container;

state Gnome::Gtk4::Grid $button-grid;
state Int $button-count = 0;
has Array $buttons = [];

#has Gnome::Gtk4::Stack $!stack;

#-------------------------------------------------------------------------------
#TM:1:set-grid
=begin pod

Get the grid from the container if the container is a dialog type. This type is derived from its name e.g. C<QA::Gui::PageSimpleDialog> is a dialog. Otherwise the container is an empty widget which will get a newly created grid.

  set-grid ( $container )

=item $container; A defined container. When it is not a dialog the widget must be empty.

=end pod

method set-grid ( $!container where .defined ) {
#note 'set-grid, container name: ', $!container.^name;

  # Set the contents of the grid depending of the type of container
  given $!container.^name {
    when m/ Dialog / {
      $!grid = $!container.dialog-content;
    }

    default {
      $!grid .= new;
      $!container.add($!grid);
    }
  }

  my Gnome::Gtk4::StyleContext() $context = $!grid.get-style-context;
  $context.add-class('QATopGrid');
}

#-------------------------------------------------------------------------------
# $!grid filling at its row and column
#   0, 0   a page, stack, notebook or assistant
#   0, 1   a stack switcher when type is a stack, otherwise empty
#   0, 2   a statusbar
#   0, 3   a button row when the container is not of the dialog type
#
#TM:1:set-grid-content
=begin pod

Set the contents of the grid. This content depends on the type of container which can be one of C<Simple>, C<Stack>, C<Notebook> or C<Assistant>

  set-grid-content ( Str $type = 'Simple' )

=item $type; The type of container.

=end pod
method set-grid-content ( Str $type = 'Simple' ) {

  # The statusbar must be created before anything else because it starts
  # to listen for status changes which are emitted when fields are placed
  # on the invoice and checked for its data
  my QA::Gui::Statusbar $statusbar .= new;
  $!grid.attach( $statusbar, 0, 2, 1, 1);

  QA::Status.instance.clear-status;

#note "set-grid-content, container type: $type";

  given $type {
    when / Simple / {
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

#      my QA::Gui::Statusbar $statusbar .= new;
#      $!grid.attach( $statusbar, 0, 1, 1, 1);
    }

    when / Stack / {
      state Gnome::Gtk4::Stack $stack;
      if !$stack {
        $stack .= new;
        $!grid.attach( $stack, 0, 0, 1, 1);
        my Gnome::Gtk4::StackSwitcher $stack-switcher .= new;
        $stack-switcher.set-stack($stack);
        $!grid.attach( $stack-switcher, 0, 1, 1, 1);
      }

      # select content pages only
      my $pages := $!qst.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $stack.add-titled(
            $page.create-content, $page-data<page-name>, $page-data<title>
          );
        }
      }
    }

    when / Notebook / {
      # create the notebook and add pages to it
      my Gnome::Gtk4::Notebook $notebook .= new;
      $!grid.attach( $notebook, 0, 0, 1, 1);

      # select content pages only
      my $pages := $!qst.clone;
      for $pages -> Hash $page-data {
        if $page-data<page-type> ~~ QAContent {
          my QA::Gui::Page $page = self!create-page( $page-data, :!description);
          $notebook.append-page(
            $page.create-content,
            Gnome::Gtk4::Label.new(:text($page-data<title>))
          )
        }
      }
    }

    when / Assistant / {
    }

#`{{
    when 'SimpleWindow' {
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

    when 'StackWindow' {
    }

    when 'NotebookWindow' {
    }

    when 'AssistantWindow' {
    }
}}
  }
}

#-------------------------------------------------------------------------------
#TM:1:add-button
=begin pod
=head2 add-button

For dialog types it is possible to add some buttons to the dialog

  method add-button (
    Str $widget-name, GtkResponseType $response-type,
    Bool :$is-dialog = True
  )

=item $widget-name; The name of the button specified in the button map from the configuration.
=item $response-type; A choice of four supported types; GTK_RESPONSE_CANCEL, GTK_RESPONSE_APPLY, GTK_RESPONSE_OK and GTK_RESPONSE_HELP
=item $is-dialog; When user wants to show the questionaire in its own widget, this value should be set to C<False>. The button normally is added at the bottom of a dialog but when set to False the buttons are added at the bottom of the grid.

=end pod
method add-button (
  Str:D $widget-name, GtkResponseType:D $response-type,
  Bool :$is-dialog = True
) {
  my Hash $button-map = $!qst.button-map // %();
  return unless $button-map{$widget-name}:exists;

#  state Gnome::Gtk4::Grid $button-grid;
#  state Int $button-count = 0;

note "add button $widget-name, $response-type, $is-dialog";

  # ???? it is possible that button is undefined
  my Gnome::Gtk4::Button $button = self!create-button(
    $widget-name, $button-map, :$is-dialog, :$response-type
  );

  # Store button. This makes it possible to hook signals from user to it.
  # Enum value is negative!
  $!buttons[$response-type.value.abs] = $button;

#note "$button.get-name()";
#  my Hash $button-map = $!qst.button-map // %();
  $button.set-can-default(True) if ? $button-map{$widget-name}<default>;

  if $is-dialog {
    self.set-default-response($response-type);
    self.add-action-widget( $button, $response-type)
  }

  else {
    if not $button-grid.defined {
#note 'new button grid';
      # create an empty box which wil push all buttons to the right
      with my Gnome::Gtk4::Box $strut .= new {
        .set-hexpand(True);
        .set-vexpand(False);
        .set-halign(GTK_ALIGN_START);
        .set-valign(GTK_ALIGN_START);
        .set-margin-top(0);
        .set-margin-start(0);
      }

      $button-grid .= new;
      $button-grid.attach( $strut, $button-count++, 0, 1, 1);

      $!grid.attach( $button-grid, 0, 3, 1, 1);
    }

    $button-grid.attach( $button, $button-count++, 0, 1, 1);
  }
}

#-------------------------------------------------------------------------------
method !create-button (
  Str $widget-name, Hash $button-map, Bool :$is-dialog = True,
  GtkResponseType:D :$response-type
  --> Gnome::Gtk4::Button
) {
  # change text of label on button when defined in the button map structure
#  my Hash $button-map = $!qst.button-map // %();
  my Str $button-text = $button-map{$widget-name}<name> // $widget-name;

  # uppercase first letter of every word.
  $button-text = $button-text.split(/<[-_\s]>+/)>>.tc.join(' ');
#note "button text: $button-text, $response-type";

  # create button and change some other parameters
  my Gnome::Gtk4::Button $button .= new(:label($button-text));
  $button.set-name($widget-name);
#note $button.gist;

  unless $is-dialog {
    given $response-type {
      when GTK_RESPONSE_CANCEL {
        $button.register-signal( self, 'cancel-response', 'clicked')
      }

      when GTK_RESPONSE_APPLY {
        $button.register-signal( self, 'apply-response', 'clicked')
      }

      when GTK_RESPONSE_OK {
        $button.register-signal( self, 'ok-response', 'clicked')
      }

      when GTK_RESPONSE_HELP {
        $button.register-signal( self, 'help-response', 'clicked')
      }
    }
  }

  $button
}

#`{{
# TODO; resize from widget values does not work because it is returning only
# values of current allocation.
#-------------------------------------------------------------------------------
method resize-container ( ) {
  my Gnome::Gtk4::Container() $c = $!grid.get-parent;
note "grid width: ", my Int $w = $!grid.get-allocated-width();
note "grid height: ", my Int $h = $!grid.get-allocated-height();

note "preferred w: ", $!grid.get-preferred-width;
note "preferred h: ", $!grid.get-preferred-height;

note "allocation: ", $!grid.get-allocation;

  $c.set-size-request( $w, $h);
}
}}

#-------------------------------------------------------------------------------
method set-callback (
  GtkResponseType:D $response-type, Mu:D $handler-object, Str:D $handler-method
) {
  my Gnome::Gtk4::Button $button = $!buttons[$response-type.value.abs];
  $button.register-signal( $handler-object, $handler-method, 'clicked');
}

#-------------------------------------------------------------------------------
method set-style ( Str:D $class-name, :$widget ) {

  if ?$widget and $widget.is-toplevel {
    my Gnome::Gdk3::Pixbuf $win-icon .= new(
      :file(%?RESOURCES<icons8-invoice-32.png>.Str)
    );

    my Gnome::Glib::Error $e = $win-icon.last-error;
    if $e.is-valid {
      die "Error icon file: $e.message()";
    }

    else {
      $widget.set-icon($win-icon);
    }
  }

  # load the gtk resource file and register resource to make data global to app
  my Gnome::Gio::Resource $r .= new(
    :load(%?RESOURCES<g-resources/QAManager.gresource>.Str)
  );
  $r.register;

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

  $context.add-class($class-name);
}

#-------------------------------------------------------------------------------
method load-user-data ( ) {
  my QA::Types $qa-types .= instance;
  $!user-data = $qa-types.qa-load( $!qst-name, :userdata);
}

#-------------------------------------------------------------------------------
method save-data ( ) {
  $!result-user-data = $!user-data;
#note 'save-data: ', $!result-user-data.gist;

  my QA::Types $qa-types .= instance;
  $qa-types.qa-save( $!qst-name, $!result-user-data, :userdata) if $!save-data;
}

#-------------------------------------------------------------------------------
# create page with all widgets on it. it always will return a
# scrollable window
method !create-page( Hash $page, Bool :$description = True --> QA::Gui::Page ) {
#note "\nPage: ", $page.<page-name>;
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
        self.destroy;     #! should be the same as $!container
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
method cancel-response ( ) {
  note 'cancel-response';

  if self.show-cancel {
    $!container.destroy;
    self!reset-button-grid;
  }
}

#-------------------------------------------------------------------------------
method ok-response ( ) {

  my QA::Status $status .= instance;

  if $status.faulty-state {
    self.show-message(
      "There are still missing or wrong answers, cannot save data"
    );
  }

  else {
    self.save-data;
    $!container.destroy;
    self!reset-button-grid;
  }
}

#-------------------------------------------------------------------------------
#multi method apply-response ( ) {
method apply-response ( ) {

  my QA::Status $status .= instance;

  if $status.faulty-state {
    self.show-message(
      "There are still missing or wrong answers, cannot save data"
    );
  }

  else {
    self.save-data;
  }

#note 'call user apply';
#  nextwith($!result-user-data);
}

#-------------------------------------------------------------------------------
method help-response ( ) {

  my Str $text = $!qst.button-map<help-info><message>;
  self.show-message($text) if ?$text;
}

#-------------------------------------------------------------------------------
method show-message ( Str:D $message --> Int ) {
  my QA::Gui::OkMsgDialog $ok .= new(:$message);
  my $r = $ok.run;
  $ok.destroy;

  $r
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {
  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.run);
    $yn.destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}

#-------------------------------------------------------------------------------
method !reset-button-grid ( ) {
  # when user widget is destroyed, the button grid should also be reset

  $button-count = 0;
  $button-grid = Nil;
  $!buttons = [];
}
