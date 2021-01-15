#tl:1:Types:

use v6.d;

use JSON::Fast;
use Config::TOML;
use YAMLish;

#-------------------------------------------------------------------------------
=begin pod
A singleton class to provide types, global variables and some routines.

=end pod

unit class QA::Types:auth<github:MARTIMM>;
#-------------------------------------------------------------------------------
=begin pod
=head1 Types
=end pod

#-------------------------------------------------------------------------------
#=begin pod
#=head2 QADataFileType
#=end pod
#tt:1:QADataFileType:
enum QADataFileType is export < QAJSON QATOML QAYAML >;

#-------------------------------------------------------------------------------
=begin pod
=head2 QAFieldType

QAFieldType is an enumeration of field types to provide an anwer. The types are (and more to come);

=item QACheckButton; A group of checkbuttons.
=comment item QADragAndDrop;
=comment item QAColorChooser;
=item QAComboBox; A pulldown list with items.
=item QAEntry; A single line of text.
=item QAFileChooser; A button to open a file dialog and choose a file.
=item QAImage; A button to open a file dialog and choose an image.
=comment item QAList; An list.
=item QARadioButton; A group of radiobuttons.
=item QAScale; A scale for numeric input.
=item QASpinButton; A spinbutton for numeric input.
=item QASwitch; On/Off, Yes/No kind of input.
=item QATextView; Multi line input.
=item QAToggleButton; Like switch.
=item QAUserWidget; A user widget. The key is given with userwidget.

=end pod

#tt:1:QAFieldType:
enum QAFieldType is export <
  QAEntry QATextView QAComboBox QARadioButton QACheckButton QASpinButton
  QAToggleButton QAScale QASwitch QAImage QAList QAFileChooser
  QAColorChooser QADragAndDrop QAUserWidget
>;

#-------------------------------------------------------------------------------
#tt:1:QADisplayType:
enum QADisplayType is export <QASimpleDialog QANotebook QAStack QAAssistant>;

#-------------------------------------------------------------------------------
#tt:1:QAPageType:
=begin pod

Page types are based on GtkAssistantPageType

=item QAContent; The page has regular contents. This is the default page type in all of the display posibilities.
=comment Both the Back and forward buttons will be shown.

=item QAIntro; The page contains an introduction to the assistant task. This could be displayed on the first tab of a Notebook, Stack or Assistant. There is no use for it in a Dialog because only one page is shown.
=comment Only the Forward button will be shown if there is a next page.

=item QAConfirm; The page lets the user confirm or deny the changes. Only useful in an Assistant.
=comment The Back and Apply buttons will be shown.

=item QASummary; The page informs the user of the changes done. Only useful in an Assistant.
=comment Only the Close button will be shown.

=item QAProgress; Used for tasks that take a long time to complete, blocks the assistant until the page is marked as complete. Only useful in an Assistant.
=comment Only the back button will be shown.

=comment item QACustom; Used for when other page types are not appropriate. No buttons will be shown, and the application must add its own buttons through gtk_assistant_add_action_widget().

=end pod
enum QAPageType is export <
  QAContent QAIntro QAConfirm QASummary QAProgress QACustom
>;

#-------------------------------------------------------------------------------
#tt:1:InputStatusHint:
enum InputStatusHint is export <QAStatusNormal QAStatusOk QAStatusFail>;

#-------------------------------------------------------------------------------
#tt:1:ActionReturnType:
enum ActionReturnType is export <
  QAOpenDialog QAHidePage QAShowPage QAHideSet QAShowSet QAEnableButton
  QADisableButton QAOtherUserAction
>;

#-------------------------------------------------------------------------------
#tt:1::QAGridColSpec
=begin pod
=head2 QAGridColSpec

Column numbers for the question-answer row in a grid

=item QAQuestion;
=item QARequired;
=item QAAnswer;
=end pod
enum QAGridColSpec is export <QAQuestion QARequired QAAnswer>;

#-------------------------------------------------------------------------------
=begin pod
=head2 AGridColSpec

Column numbers for the grid in the answer part of the QA

=item QACatColumn;
=item QAInputColumn;
=item QAButtonColumn;
=end pod
#tt:1::AGridColSpec
enum AGridColSpec is export <QACatColumn QAInputColumn QAButtonColumn>;


#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
my QA::Types $instance;

has Hash $!user-objects;

#-------------------------------------------------------------------------------
my QADataFileType $data-file-type;
method data-file-type ( QADataFileType $ftype ) {
  $data-file-type = $ftype;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-userdata;
method cfgloc-userdata ( Str $dir ) {
  $cfgloc-userdata = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-category;
method cfgloc-category ( Str $dir ) {
  $cfgloc-category = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-sheet;
method cfgloc-sheet ( Str $dir ) {
  $cfgloc-sheet = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-set;
method cfgloc-set ( Str $dir ) {
  $cfgloc-set = $dir;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 new

The class is a singleton class where C<.new()> is prevented to be used. The call will throw an exception. To get the object, call C<.instance()>.
=end pod

#tm:1:new
submethod new ( ) { !!! }

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  self!init
}

#-------------------------------------------------------------------------------
=begin pod
=head2 instance

The users application can modify the variables before opening any query sheets. The following variables are used in this program;

=item QADataFileType C<$data-file-type>; You can choose from QAJSON or QATOML. By default it loads and saves the answers to questions in json formatted files.


=item Str C<$cfgloc-category>; Location where categories are stored. Default is C<$!HOME/.config/QAManager/Categories.d> on *nix systems.
=item Str C<$cfgloc-set>; Location where sets are stored. Default is C<$!HOME/.config/QAManager/Sets.d> on *nix systems.
=item Str C<$cfgloc-sheet>; Location where sheets are stored. Default is C<$!HOME/.config/QAManager/Sheets.d> on *nix systems.
=item Str C<$cfgloc-userdata>; Location where userdata is stored. Default is C<$!HOME/.config/<modified $*PROGRAM-NAME>> on *nix systems.

If any of C<$cfgloc-category>, C<$cfgloc-sheet>, C<$cfgloc-set> or C<$cfgloc-userdata> is changed, make sure that the directories exists!

=end pod

#tm:1:instance
method instance ( --> QA::Types ) {
  $instance //= self.bless;

  $instance
}

#`{{
#-------------------------------------------------------------------------------
=begin pod
=head2 qa-path

Return a path where a QA based sheet or category should be found. When C<:userdata> is used, the user info for the sheet is searched for.

  multi method qa-path( Str:D $qa-filename, :sheet --> Str )
  multi method qa-path( Str:D $qa-filename, :userdata --> Str )
  multi method qa-path( Str:D $qa-filename --> Str )

=item Str $qa-filename; the filename for the sheet, userdata or category.

=end pod

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-path( Str:D $qa-filename, Bool :$set! --> Str ) {
  "$cfgloc-set/$qa-filename.cfg";
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-path( Str:D $qa-filename, Bool :$userdata! --> Str ) {
  "$cfgloc-userdata/$qa-filename.cfg";
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-path( Str:D $qa-filename --> Str ) {
  "$cfgloc-category/$qa-filename.cfg";
}
}}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-load

Load a config or data file into a Hash. There is no use for it directly. To load data, use the modules B<QManager::Set> or B<QManager::Sheet>. The type of the file is taken from the $data-file-type. Only one of the options sheet, set, category or userdata can be used.

  multi method qa-load (
    Str:D $qa-filename, :sheet?, :set?, :userdata?, :category?, Str :$qa-path?
    --> Hash
  )

=item Str $qa-filename; the filename for the category or sheet.
=item $sheet; load a sheet if option exists.
=item $set; load a set if option exists.
=item $category; load a category if option exists.
=item $userdata; load a userdata if option exists.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.
=end pod


#tm:1:qa-load
method qa-load( Str:D $qa-filename, *%options --> Hash ) {
  my Str $basename = '';
  my Hash $qa-data;
  my Str $qa-path = %options<qa-path> // Str;

  if !$qa-path {
    if %options<sheet>:exists       { $basename = $cfgloc-sheet; }
    elsif %options<set>:exists      { $basename = $cfgloc-set; }
    elsif %options<userdata>:exists { $basename = $cfgloc-userdata; }
    elsif %options<category>:exists { $basename = $cfgloc-category; }
    else                            { $basename = $cfgloc-category; }
  }

  given $data-file-type {
    when QAJSON {
      $qa-path //= "$basename/$qa-filename.json";
      $qa-data = from-json($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when QATOML {
      $qa-path //= "$basename/$qa-filename.toml";
      $qa-data = from-toml($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when QAYAML {
      $qa-path //= "$basename/$qa-filename.yaml";
      $qa-data = load-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }
  }

  $qa-data
}

#`{{
#tm:1:qa-load
multi method qa-load (
  Str:D $qa-filename, Bool :$set!, Str :$qa-path? is copy
  --> Hash
) {
  $qa-path //= self.qa-path( $qa-filename, :set);

  my Hash $data;
  given $qa-filename.IO.extension {
    when 'json' {
      $data = from-json($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when 'yaml' {
      $data = from-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when 'toml' {
      $data = from-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }
  }

  $data // Hash
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-load (
  Str:D $qa-filename, Bool :$sheet!, Str :$qa-path? is copy
  --> Hash
) {
  $qa-path //= self.qa-path( $qa-filename, :sheet);

  my Hash $data;
  given $qa-path.IO.extension {
    when 'json' {
      $data = from-json($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when 'yaml' {
      $data = from-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when 'toml' {
      $data = from-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }
  }

  $data // Hash
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-load (
  Str:D $qa-filename, Bool :$userdata!, Str :$qa-path? is copy
  --> Hash
) {
  my Hash $data;

  $qa-path //= self.qa-path( $qa-filename, :userdata);
  given $data-file-type {
    when QAJSON {
      $qa-path ~~ s/ \.cfg $/.json/;
      $data = from-json($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when QATOML {
      $qa-path ~~ s/ \.cfg $/.toml/;
      $data = from-toml($qa-path.IO.slurp) if $qa-path.IO.r;
    }

    when QAYAML {
      $qa-path ~~ s/ \.cfg $/.yaml/;
      $data = load-yaml($qa-path.IO.slurp) if $qa-path.IO.r;
    }
  }

  $data // Hash
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
multi method qa-load ( Str:D $qa-filename, Str :$qa-path? is copy --> Hash ) {
  $qa-path //= self.qa-path($qa-filename);
  my Hash $data = from-json($qa-path.IO.slurp) if $qa-path.IO.r;
  $data // Hash
}
}}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-save

Save a Hash of QA type data into a file. There is no use for it directly. To save data, use the modules B<QManager::Category> or B<QManager::Sheet>. C<:userdata> is used to save data read from the forms.

  multi method qa-save (
    Str:D $qa-filename, Hash:D $qa-data, :sheet!, Str :$qa-path?
  )

  multi method qa-save (
    Str:D $qa-filename, Hash:D $qa-data, :userdata!, Str :$qa-path?
  )

  multi method qa-save (
    Str:D $qa-filename, Hash:D $qa-data, Str :$qa-path?
  )

=item Str $qa-filename; the filename for the category or sheet.
=item Hash $qa-data; sheet or category data.
=item Bool $sheet; switch between sheet or category.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and $sheet are then ignored.
=end pod

#tm:1:qa-save
method qa-save( Str:D $qa-filename, Hash $qa-data, *%options ) {
  my Str $basename = '';
  my Str $qa-path = %options<qa-path> // Str;

  if !$qa-path {
    if %options<sheet>:exists       { $basename = $cfgloc-sheet; }
    elsif %options<set>:exists      { $basename = $cfgloc-set; }
    elsif %options<userdata>:exists { $basename = $cfgloc-userdata; }
    elsif %options<category>:exists { $basename = $cfgloc-category; }
    else                            { $basename = $cfgloc-category; }
  }

  given $data-file-type {
    when QAJSON {
      $qa-path //= "$basename/$qa-filename.json";
      $qa-path.IO.spurt(to-json($qa-data));
    }

    when QATOML {
      $qa-path //= "$basename/$qa-filename.toml";
      $qa-path.IO.spurt(to-toml($qa-data));
    }

    when QAYAML {
      $qa-path //= "$basename/$qa-filename.yaml";
      $qa-path.IO.spurt(save-yaml($qa-data));
    }
  }
}

#`{{
#tm:1:qa-save
multi method qa-save (
  Str:D $qa-filename, Hash:D $qa-data, Bool :$sheet!, Str :$qa-path is copy
) {
  $qa-path //= self.qa-path( $qa-filename, :sheet);
  $qa-path.IO.spurt(to-json($qa-data));
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:qa-save
multi method qa-save (
  Str:D $qa-filename, Hash:D $qa-data, Bool :$set!, Str :$qa-path is copy
) {
  $qa-path //= self.qa-path( $qa-filename, :set);
  $qa-path.IO.spurt(to-json($qa-data));
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:qa-save
multi method qa-save (
  Str:D $qa-filename, Hash:D $qa-data, Bool :$userdata!, Str :$qa-path is copy
) {
  $qa-path //= self.qa-path( $qa-filename, :userdata);
  given $data-file-type {
    when QAJSON {
      $qa-path ~~ s/ \.cfg $/.json/;
      $qa-path.IO.spurt(to-json($qa-data));
    }

    when QATOML {
      $qa-path ~~ s/ \.cfg $/.toml/;
      $qa-path.IO.spurt(to-toml($qa-data));
    }

    when QAYAML {
      $qa-path ~~ s/ \.cfg $/.yaml/;
      $qa-path.IO.spurt(save-yaml($qa-data));
    }
  }
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:qa-save
multi method qa-save (
  Str:D $qa-filename, Hash:D $qa-data, Str :$qa-path is copy
) {
  $qa-path //= self.qa-path($qa-filename);
  $qa-path.IO.spurt(to-json($qa-data));
}
}}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-remove

Remove a QA type data file. There is no use for it directly. To remove data, use the modules B<QManager::Category> or B<QManager::Sheet>.

  method qa-remove (
    Str:D $qa-filename, Bool :$sheet = False, Str :$qa-path
  )

=item Str $qa-filename; the filename for the category or sheet.
=item Bool $sheet; switch between sheet or category.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and $sheet are then ignored.
=end pod

#tm:1:qa-remove
method qa-remove (
#  Str:D $qa-filename, Bool :$sheet = False, Str :$qa-path is copy
  Str:D $qa-filename, *%options
) {
  my Str $basename = '';
  my Str $qa-path = %options<qa-path> // Str;

  if !$qa-path {
    if %options<sheet>:exists       { $basename = $cfgloc-sheet; }
    elsif %options<set>:exists      { $basename = $cfgloc-set; }
    elsif %options<userdata>:exists { $basename = $cfgloc-userdata; }
    elsif %options<category>:exists { $basename = $cfgloc-category; }
    else                            { $basename = $cfgloc-category; }
  }

  given $data-file-type {
    when QAJSON {
      $qa-path //= "$basename/$qa-filename.json";
    }

    when QATOML {
      $qa-path //= "$basename/$qa-filename.toml";
    }

    when QAYAML {
      $qa-path //= "$basename/$qa-filename.yaml";
    }
  }

  unlink $qa-path;

#`{{
  $qa-path //= $sheet
            ?? self.qa-path( $qa-filename, :sheet)
            !! self.qa-path( $qa-filename);
  unlink $qa-path;
}}
}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-list

Get the list of sheets or categories stored.

  method qa-list ( Bool :$sheet = False, Str :$qa-path --> List )

=item Bool $sheet; switch between sheet or category.
=item Str $qa-path; optional path to locate the file. The value of $sheet is then ignored.
=end pod

#tm:1:qa-list
method qa-list ( *%options --> List ) {
  my Str $basename = '';
  my Str $qa-path = %options<qa-path> // Str;

  if %options<qa-path> {
    $basename = $qa-path;
  }

  else {
    if %options<sheet>:exists       { $basename = $cfgloc-sheet; }
    elsif %options<set>:exists      { $basename = $cfgloc-set; }
    elsif %options<userdata>:exists { $basename = $cfgloc-userdata; }
    elsif %options<category>:exists { $basename = $cfgloc-category; }
    else                            { $basename = $cfgloc-category; }
  }

  my @qa-list = ();
  for (dir $basename)>>.Str -> $qa-filename is copy {
    # only keep the name of the sheet or category without extensions
    $qa-filename ~~ s/ ^ .*? (<-[/]>+ ) \. \w+ $ /$0/;
    @qa-list.push($qa-filename);
  }

  @qa-list
}

#`{{
method qa-list ( Bool :$sheet = False, Str :$qa-path is copy --> List ) {
  $qa-path //= self.qa-path( '__', :$sheet);
  $qa-path ~~ s/ '/__.cfg' //;

  my @qa-list = ();
  for (dir $qa-path)>>.Str -> $qa-filename is copy {
    # only keep the name of the sheet or category without extensions
    $qa-filename ~~ s/ ^ .*? (<-[/]>+ ) \. 'cfg' $ /$0/;
    @qa-list.push($qa-filename);
  }

  @qa-list
}
}}

#-------------------------------------------------------------------------------
=begin pod
=head2 set-handler

set-handler is used to set a user defined callback handler. When in a question the callback specification is used, the value of it is used to find the callback. Callbacks can have one of two purposes. First is to check an input from the sheet. Second is to perform some action (this is not implemented yet).

  method set-action-handler (
    Str:D $callback-key, Mu:D $handler-object, Str:D $method-name,
    *%options
  )

  method set-check-handler (
    Str:D $callback-key, Mu:D $handler-object, Str:D $method-name,
    *%options
  )

=end pod

#tm:1:set-action-handler
method set-action-handler (
  Str:D $action-key, Mu:D $handler-object, Str:D $method-name, *%options
) {
  $!user-objects<actions>{$action-key} = [
    $handler-object, $method-name, %options
  ];
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:set-check-handler
method set-check-handler (
  Str:D $check-key, Mu:D $handler-object, Str:D $method-name, *%options
) {
  $!user-objects<checks>{$check-key} = [
    $handler-object, $method-name, %options
  ];
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:set-widget-object
method set-widget-object ( Str:D $widget-key, Mu:D $widget-object ) {
  $!user-objects<widgets>{$widget-key} = $widget-object;
}

#-------------------------------------------------------------------------------
#tm:1:get-action-handler
method get-action-handler ( Str:D $action-key --> Array ) {
  $!user-objects<actions>{$action-key}
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:get-check-handler
method get-check-handler ( Str:D $check-key --> Array ) {
  $!user-objects<checks>{$check-key}
}

#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#tm:1:get-widget-object
method get-widget-object ( Str:D $widget-key --> Any ) {
  $!user-objects<widgets>{$widget-key}
}

#-------------------------------------------------------------------------------
#tm:1:!init:
method !init ( ) {

  $data-file-type //= QAJSON;
  $!user-objects = %(
    actions => %(),
    checks => %(),
    widgets => %(),
  );

  self.reinit-dirs;
}

#-------------------------------------------------------------------------------
#tm:1:reinit:
method reinit-dirs ( ) {

  if $*DISTRO.is-win {
  }

  else {
    $cfgloc-category //= "$*HOME/.config/QAManager/Categories.d";
    mkdir( $cfgloc-category, 0o760) unless $cfgloc-category.IO.d;

    $cfgloc-sheet //= "$*HOME/.config/QAManager/Sheets.d";
    mkdir( $cfgloc-sheet, 0o760) unless $cfgloc-sheet.IO.d;

    $cfgloc-set //= "$*HOME/.config/QAManager/Sets.d";
    mkdir( $cfgloc-set, 0o760) unless $cfgloc-set.IO.d;

    my Str $pname //= $*PROGRAM-NAME.IO.basename;
    $pname ~~ s/ \. <-[.]>* $//;
    $cfgloc-userdata //= "$*HOME/.config/$pname";
    mkdir( $cfgloc-userdata, 0o760) unless $cfgloc-userdata.IO.d;
  }
}
