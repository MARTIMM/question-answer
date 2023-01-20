#!/usr/bin/env -S raku -Ilib -I.

#-------------------------------------------------------------------------------
use lib '/home/marcel/Languages/Raku/Projects/question-answer/lib';

use YAMLish;

use QA::Gui::PageSimpleWindow;
use QA::Gui::PageStackWindow;
use QA::Gui::PageNotebookWindow;
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
constant \PageNotebookWindow = QA::Gui::PageNotebookWindow;

#-------------------------------------------------------------------------------
# A very small class just to have a method to quit the event queue
class QstDialog {
  method exit-app ( ) {
    Main.new.quit;
  }
}

#-------------------------------------------------------------------------------
# Get commandline options
my Str $lib-path;
my Str $script;
my Str $data-file-name;
my Str $qst-name;
my Bool $help;

{ get-options(
    'I=s' => $lib-path, 'D=s' => $data-file-name, 'Q=s' => $qst-name,
    'h' => $help
  );

  if $help {
    USAGE;
    exit 0;
  }

  unless @*ARGS[0].IO.r {
    note "No protocol file found";
    USAGE;
    exit 1;
  }

  # When -I is used, a lib name must be added to the RAKULIB environment
  # variable and the program restarted without the -I option
  if ?$lib-path {
    # Change module search paths%*ENV<RAKULIB>
    %*ENV<RAKULIB> =
      %*ENV<RAKULIB>:exists ?? %*ENV<RAKULIB> ~ ",$lib-path" !! $lib-path;

    # Turn on debugging
    #%*ENV<RAKUDO_MODULE_DEBUG> = 1;

    # Prepare command to restart this program
    my Str @cmd = $*PROGRAM-NAME,
        ?$data-file-name ?? "-D $data-file-name" !! '',
        ?$qst-name ?? "-Q $qst-name" !! '',
        |@*ARGS;

    # Restart in background and exit this program
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

#note


#-------------------------------------------------------------------------------
# Continue here when -I option is not found. -I is removed after restart and
# environment variable RAKULIB is set.

my QstDialog $qdialog .= new;
my Window $window .= new;

# Load the protocol from the script and initialize the lot
$script = @*ARGS[0];
my Hash $cfg = load-yaml($script.IO.slurp);

#  note "\n\nquestionnaire: ", $qa-types.get-file-path( $qst-name, :sheet);
#  note 'Results: ', $qa-types.get-file-path(
#    ?$data-file-name ?? $data-file-name !! $qst-name, :userdata
#  );

init-qa( $cfg, $data-file-name);
init-callbacks($cfg);
init-theme( $cfg, $window);

my $qst-window = init-questionnaire( $cfg, $window, $qst-name);

# Prepare for the window destroy and show it
$window.register-signal( $qdialog, 'exit-app', 'destroy');
$window.show-all;

# start event loop
Main.new.main;


#-------------------------------------------------------------------------------
# After normal finish, show results and the status of the questionnaire
$qst-window.show-hash;

my QA::Status $status .= instance;
if $status.faulty-state {
  note 'State of questionnaire: incomplete and/or wrong';
  for $status.faulty-states.kv -> $name, $state {
    note "  faulty item: $name";
  }
}

else {
  note 'State of questionnaire: ok';
}

#-------------------------------------------------------------------------------
# Show how to start when there is an error in the commandline
sub USAGE ( ) {
  note Q:s:to/EOUSAGE/;

  Usage;
    $*PROGRAM-NAME.IO.basename() <options> <script>

  Options;
    -D<data filename>   Optional name of datafile. When absent, the program
                        looks for the 'data-file-name' key in the protocol file.
                        Otherwise it takes the programs name without the
                        extension.
    -I<path list>       List of paths where user modules can be found.
    -Q<questionnaire>   Name of invoice to select. When absent, the program
                        looks for the 'questionnaire' key in the protocol file.
                        This name must be defined.
    -h                  Display this information

  Script;
    The script file is a yaml formatted file which describes which questionnaire
    to use, where to find it, where to store the result amongst other things.
    Its extension should be '.qascript'.

  Script Format;
    The first line should be '#qascript' usable as a kind of magic string.
    The type of file can be recognized with this string as well as with
    the extension of the file, which should be '.qascript'.

    The keys used in the file are the following.

    path: …                   A path to where data is stored and files found
    store-type: …             Type of all files, 'yaml', 'json' or 'toml'
    versioned: false          Data store is versioned with an extra number
                              tagged to the filename. Default is false.
    version: 0                Starting number to use as version. Default is 0.

    check-callbacks:          Define this when questionnaire uses a routine to
                              check input. Perhaps -I must be used or RAKULIB
                              environment variable must be set.
      ModuleA:                Example module name.
      - check-method1         Example method name. There can be more methods

    action-callbacks:         Define this when questionnaire uses a routine
                              after input is finished. Perhaps -I must be used
                              or RAKULIB environment variable must be set.
      ModuleB:                Example module name.
      - action-method1        Example method name. There can be more methods
      - action-method2


    questionnaire: …          The name of the questionnaire
    questionnaire-type:       The type of presentation, 'simple', 'stack' or
                              'notebook'.

                              A few control control keys which tell how to
                              process the questionnaire.
    show-cancel-warning: true
    show-data-on-exit: true
    save-data: true

  EOUSAGE
}

#-------------------------------------------------------------------------------
sub init-qa ( Hash:D $cfg, Str $data-file-name? is copy ) {
  # Find and modify paths
  my Str $path = $cfg<path> // Str;
  my Str $extension = $cfg<extension> // Str;
  my Str $versioned = $cfg<versioned> // Str;
  my Int $version = $cfg<version> // 0;

  # if -Q is not set then questionnaire comes from script, otherwise undefined
  $qst-name //= $cfg<questionnaire> // Str;

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
sub init-questionnaire ( Hash:D $cfg, $widget, Str $qst-name ) {

  my Bool $show-cancel-warning = $cfg<show-cancel-warning> // False;
  my Bool $save-data = $cfg<save-data> // False;

  given $cfg<questionnaire-type> {
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
      $qst-window = PageNotebookWindow.new(
        :$qst-name, :$show-cancel-warning, :$save-data, :$widget,
      );
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
