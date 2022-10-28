#!/usr/bin/env -S raku -Ilib -I.

#`{{
  Program to be run on files with the .mt01 extension. The content of such files
  are a magic code followed my yaml content

  This content is a simple set of two keys 'data' and 'gst'
  Example file;

  ---[ file example ]-----------------------------------------------------------
  #mt01

  # Above code is a magic code. However, it is not checked anywhere and the
  # linux 'file(1)' command does not use it and only shows 'ASCII text'.
  # However, still put it there because it also gives info about which program
  # starts when clicking on the file. Perhaps there are some hidden checks.

  # Type of storage, one of yaml, toml or json
  store-type: yaml

  # Type of dialog to use; simple, stack, notebook or assistant
  qst-type: Stack

  # The location where data from questionaire is stored. Default at
  # $HOME/.local/share/mt01/Data
  data: /home/marcel/Languages/Raku/Projects/question-answer/xbin/Data

  # The location where questionaires are found Default at
  # $HOME/.local/share/mt01/Qsts
  qsts: /home/marcel/Languages/Raku/Projects/question-answer/xbin/Data/Qst


  # name of the questionaire
  questionaire: StackTest

  ---[ end example ]------------------------------------------------------------
}}

#-------------------------------------------------------------------------------
use lib '/home/marcel/Languages/Raku/Projects/question-answer/lib';

use YAMLish;

use QA::Gui::PageSimpleWindow;
use QA::Gui::PageStackWindow;
use QA::Types;

use Gnome::Gtk3::Window;
use Gnome::Gtk3::Main;
use Gnome::Gtk3::StyleContext;
use Gnome::Gtk3::StyleProvider;
use Gnome::Gtk3::CssProvider;

use Getopt::Long;

#-------------------------------------------------------------------------------
constant \Window = Gnome::Gtk3::Window;
constant \Main = Gnome::Gtk3::Main;

constant \PageSimpleWindow = QA::Gui::PageSimpleWindow;
constant \PageStackWindow = QA::Gui::PageStackWindow;

#-------------------------------------------------------------------------------
class QstDialog {
  method exit-app ( ) {
    Main.new.gtk-main-quit;
  }
}

#-------------------------------------------------------------------------------
#note "\nstart env: %*ENV<RAKULIB>";

# Get commandline options
my Str $lib-path;
my Str $script;
my Str $data-file-name;
my Str $qst-name;
#my @all-arguments = @*ARGS;
{ get-options(
    'I=s' => $lib-path, 'D=s' => $data-file-name, 'Q=s' => $qst-name
  );

  #$data-file-name //= '';
  #$qst-name //= '';

  if ?$lib-path {
    # Change module search paths%*ENV<RAKULIB>
    %*ENV<RAKULIB> =
      %*ENV<RAKULIB>:exists ?? %*ENV<RAKULIB> ~ ",$lib-path" !! $lib-path;
note 'modify env: ', %*ENV<RAKULIB>;

    # Turn on debugging
    #%*ENV<RAKUDO_MODULE_DEBUG> = 1;

    # Prepare command to restart this program
    my Str @cmd = $*PROGRAM-NAME,
        ?$data-file-name ?? "-D $data-file-name" !! '',
        ?$qst-name ?? "-Q $qst-name" !! '',
        |@*ARGS;

    # Restart in background and exit this program
note 'restart with: ', @cmd.join(' ') ~ ' &';
    shell @cmd.join(' ') ~ ' &';
    exit;
  }

  CATCH {
    when Getopt::Long::Exception {
      .message.note;
      USAGE;
    }
  };
}

note



my QstDialog $qdialog .= new;
my Window $window .= new;

$script = @*ARGS[0];
my Hash $cfg = load-yaml($script.IO.slurp);

#  note "\n\nQuestionaire: ", $qa-types.get-file-path( $qst-name, :sheet);
#  note 'Results: ', $qa-types.get-file-path(
#    ?$data-file-name ?? $data-file-name !! $qst-name, :userdata
#  );

init-qa( $cfg, $data-file-name);
init-callbacks($cfg);
init-theme( $cfg, $window);
$window.register-signal( $qdialog, 'exit-app', 'destroy');
my $qst-window = init-questionaire( $cfg, $window, $qst-name);
$window.show-all;

Main.new.main;



$qst-window.show-hash;

my QA::Status $status .= instance;
if $status.faulty-state {
  note 'State of questionaire: incomplete and/or wrong';
  for $status.faulty-states.kv -> $name, $state {
    note "  faulty item: $name";
  }
}

else {
  note 'State of questionaire: ok';
}

#-------------------------------------------------------------------------------
sub USAGE ( ) {
  note Q:s:to/EOUSAGE/;

  Usage;
  $*PROGRAM-NAME.IO.basename() <options> <protocol>

  Protocol is a yaml formatted file which describes which questionaire
  to use, where to find it, where to store the result amongst other things.
  Its extension should be '.qascript'.

  Options;
    -I<path list>       List of paths where user modules can be found.

  EOUSAGE
}

#-------------------------------------------------------------------------------
sub init-qa ( Hash:D $cfg, Str $data-file-name? is copy ) {
  # Find and modify paths
  my Str $path = $cfg<path> // Str;
  my Str $extension = $cfg<extension> // Str;
  my Str $versioned = $cfg<versioned> // Str;
  my Int $version = $cfg<version> // 0;

  # if -Q is not set then questionaire comes from script, otherwise undefined
  $qst-name //= $cfg<questionaire> // Str;

  # if -D is not set take the name from script for data store
  $data-file-name //= $cfg<data-file-name> // Str;

  # Find data store type
  my QAFileType $dftype;
  given $cfg<store-type> {
    when 'yaml' { $dftype = QAYAML; }
    when 'toml' { $dftype = QATOML; }
    when 'json' { $dftype = QAJSON; }
    default { $dftype = QAYAML; }
  }

  # Initialize QA system with these values
  given my QA::Types $qa-types {
    .data-file-name($data-file-name) if ?$data-file-name;

    .data-file-type($dftype);
    .set-root-path($path);
    .set-extension($extension) if ?$extension;
  }
}

#-------------------------------------------------------------------------------
sub init-callbacks ( Hash:D $cfg ) {
  # Search for any external modules, program may be started using -I option
  # Check callbacks
  my QA::Types $qa-types .= instance;
  if $cfg<check-callbacks>:exists {
    for $cfg<check-callbacks>.keys -> $module-name {
      #my Str $module = $cfg<check-callbacks>{$module-name};
      for @($cfg<check-callbacks>{$module-name}) -> $callback {
        $qa-types.set-check-handler( $callback, :$module-name);
      }
    }
  }

  # Action callbacks
  if $cfg<action-callbacks>:exists {
    for $cfg<action-callbacks>.keys -> $module-name {
      #my Str $module = $cfg<action-callbacks>{$module-name};
      for @($cfg<action-callbacks>{$module-name}) -> $callback {
        $qa-types.set-action-handler( $callback, :$module-name);
      }
    }
  }
}

#-------------------------------------------------------------------------------
sub init-theme ( Hash:D $cfg, $widget ) {
  return unless $cfg<theme>:exists;

  my Gnome::Gtk3::StyleContext() $context = $widget.get-style-context;
  $context.add-class('QAWidget');

  my Str $css = '';
  for $cfg<theme>.keys -> $object {
    $css ~= [~] "\n", $object, ' {', "\n";
    for $cfg<theme>{$object}.kv -> $item, $value {
      $css ~= "  $item: $value;\n";
    }

    $css ~= '}';
  }

note "\ncss:\n$css";

  my Gnome::Gtk3::CssProvider $css-provider .= new;
  $css-provider.load-from-data($css);

  $context.add-provider-for-screen(
    Gnome::Gdk3::Screen.new, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $context.clear-object;
}

#-------------------------------------------------------------------------------
sub init-questionaire ( Hash:D $cfg, $widget, Str $qst-name ) {

  my Bool $show-cancel-warning = $cfg<show-cancel-warning> // False;
  my Bool $save-data = $cfg<save-data> // False;

  given $cfg<qst-type> {
    when 'simple' {
      $qst-window = PageSimpleWindow.new(
        :$qst-name, :$show-cancel-warning, :$save-data, :$widget,
      );
    }

    when 'stack' {
      $qst-window = PageStackWindow.new(
        :$qst-name, :$show-cancel-warning, :$save-data, :$widget,
      );
    }

    when 'notebook' {
      $qst-window = '';
    }

    when 'assistant' {
      $qst-window = '';
    }

    default {
      $qst-window = PageSimpleWindow.new(
        :$qst-name, :$show-cancel-warning, :$save-data, :$widget,
      );
    }
  }
}
