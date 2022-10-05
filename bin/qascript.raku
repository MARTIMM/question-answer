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

  #note 'options: ', $lib-path //'-';
  #note "Args: $*PROGRAM-NAME, ", @*ARGS.join(', ');

  CATCH {
    when Getopt::Long::Exception {
      .message.note;
      USAGE;
    }
  };
}

note

$script = @*ARGS[0];


my Hash $cfg = load-yaml($script.IO.slurp);

# Find and modify paths
my Str $path = $cfg<path> // Str;
my Str $extension = $cfg<extension> // Str;
my Str $versioned = $cfg<versioned> // Str;
my Int $version = $cfg<version> // 0;

# if -Q is not set then questionaire comes from script, otherwise undefined
$qst-name //= $cfg<questionaire> // Str;

# if -D is not set take the name from script for data store
$data-file-name //= $cfg<data-file-name>;

my Bool $show-cancel-warning = $cfg<show-cancel-warning> // False;
my Bool $show-data-on-exit = $cfg<show-data-on-exit> // False;
my Bool $save-data = $cfg<save-data> // False;

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

  note "\n\nQuestionaire: ", $qa-types.get-file-path( $qst-name, :sheet);
  note 'Results: ', $qa-types.get-file-path(
    ?$data-file-name ?? $data-file-name !! $qst-name, :userdata
  );
}

# Search for any external modules, program may be started using -I option
# Check callbacks
$qa-types .= instance;
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

my QstDialog $qdialog .= new;
my Window $window .= new;
$window.register-signal( $qdialog, 'exit-app', 'destroy');

my $qst-window;
given $cfg<qst-type> {
  when 'simple' {
    $qst-window = PageSimpleWindow.new(
      :$qst-name, :$show-cancel-warning, :$save-data, :widget($window),
    );
  }

  when 'stack' {
    $qst-window = PageStackWindow.new(
      :$qst-name, :$show-cancel-warning, :$save-data, :widget($window),
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
      :$qst-name, :$show-cancel-warning, :$save-data, :widget($window),
    );
  }
}

$window.show-all;
#$qst-window.show-qst;

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
