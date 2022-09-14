#tl:1:Types:

use v6.d;

use JSON::Fast;
use Config::TOML;
use YAMLish;

#-------------------------------------------------------------------------------
=begin pod
A singleton class to provide types, global variables and some routines.

=end pod

unit class QA::Types:auth<github:MARTIMM>:ver<0.2.0>;
#-------------------------------------------------------------------------------
=begin pod
=head1 Types
=end pod

#-------------------------------------------------------------------------------
#=begin pod
#=head2 QAFileType
#=end pod
#tt:1:QAFileType:
enum QAFileType is export < QAJSON QATOML QAYAML >;

#-------------------------------------------------------------------------------
#=begin pod
#=head2 QAFileExtension
#=end pod
#tt:1:QAFileExtension:
#enum QAFileExtension is export < qsts sets data >;

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
=comment item QAList; A list.
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
=begin pod
=head2 ActionReturnType

Action types used in an Array of Hashes returned from an action callback.

=item QAHidePage; Hide a pages of sets
=item QAHideSet; Hide a set
=item QAHideQuestion; Hide a question

=item QAShowPage; Show a pages of sets
=item QAShowSet; Show a set
=item QAShowQuestion; Show a question

=item QAEnableInputWidget; Enable an input widget
=item QADisableInputWidget; Disable an input widget

=item QAAddQuestion; Add a new question
=item QARemoveQuestion; Remove a question
=item QAModifyQuestion; Modify a question

=item QAAddSet; Add a set of questions
=item QARemoveSet; Remove a set

=item QAAddPage; Add a page of sets
=item QARemovePage; Remove a page

=item QAOpenDialog; Open a message dialog
=item QAOtherUserAction; Call another user action registered with C<set-action-handler()>
=comment item QAModifySelectlist; Modify the list shown in a combobox used with a question
=comment item QAModifyFieldlist; Modify the list shown in a combobox used as an input field
=item QAModifyValue; Modify a value of another question. The value is checked and inserted when valid.

=item QAEnableButton; Enable a button on the page
=item QADisableButton; Disable a button on the page
=end pod

#tt:1:ActionReturnType:
enum ActionReturnType is export <
  QAHidePage QAHideSet QAHideQuestion
  QAShowPage QAShowSet QAShowQuestion

  QAAddQuestion QAAddSet QAAddPage
  QARemoveQuestion QARemoveSet QARemovePage
  QAModifyQuestion

  QAEnableInputWidget QADisableInputWidget

  QAOpenDialog QAOtherUserAction

  QAModifyFieldlist QAModifySelectlist

  QAModifyValue

  QAEnableButton QADisableButton

>;


#-------------------------------------------------------------------------------
=begin pod
=head2 QAGridColSpec

Column numbers for the question-answer row in a grid

=item QAQuestion; Column were the question is asked
=item QARequired; Column to show a '*' when question is required to answer
=item QAAnswer; Column for the input widget

=end pod

#tt:1::QAGridColSpec
enum QAGridColSpec is export <QAQuestion QARequired QAAnswer>;

#-------------------------------------------------------------------------------
=begin pod
=head2 AGridColSpec

Column numbers for the grid in the answer part of the QA

=item QACatColumn; Location in the input widget where optionally a combobox is displayed
=item QAInputColumn; The widget to set the input. This can be an Entry, Checkbox, etc.
=item QAToolButtonAddColumn; Toolbutton to add a new input row when input is repeatable
=item QAToolButtonDelColumn; Toolbutton to remove an input row when input is repeatable

=end pod

#tt:1::AGridColSpec
enum AGridColSpec is export <
  QACatColumn QAInputColumn QAToolButtonAddColumn QAToolButtonDelColumn
>;

#QAButtonColumn

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=end pod

#-------------------------------------------------------------------------------
my QA::Types $instance;

has Hash $!user-objects;

#-------------------------------------------------------------------------------
my QAFileType $data-file-type;
method data-file-type ( QAFileType $ftype? ) {
  $data-file-type = $ftype // QAJSON;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-userdata;
method cfgloc-userdata ( Str $dir? ) {
  $cfgloc-userdata = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-sheet;
method cfgloc-sheet ( Str $dir? ) {
  $cfgloc-sheet = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfgloc-set;
method cfgloc-set ( Str $dir? ) {
  $cfgloc-set = $dir;
}

#-------------------------------------------------------------------------------
my Str $cfg-root = $*PROGRAM-NAME.IO.basename;
$cfg-root ~~ s/ \. <-[.]>* $//;
method cfg-root ( Str:D $dir? ) {
  if ?$dir {
    $cfg-root = $dir;
  }

  else {
    $cfg-root = $*PROGRAM-NAME.IO.basename;
    $cfg-root ~~ s/ \. <-[.]>* $//;
  }
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
  $data-file-type //= QAJSON;
  $!user-objects = %(
    actions => %(),
    checks => %(),
    widgets => %(),
  );

  self.init-dirs;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 instance

The users application can modify the variables before opening any query sheets. The following variables are used in this program;

=item QAFileType C<$data-file-type>; You can choose from QAJSON, QAYAML or QATOML. By default it loads and saves the answers to questions in json formatted files.

=item Str C<$cfgloc-set>; Location where sets are stored. Default is C<$!HOME/.config/$cfg-root/Sets.d> on *nix systems. Use C<cfgloc-set()> to change it.
=item Str C<$cfgloc-sheet>; Location where sheets are stored. Default is C<$!HOME/.config/$cfg-root/Qsts.d> on *nix systems. Use C<cfgloc-sheet()> to change it.
=item Str C<$cfgloc-userdata>; Location where userdata is stored. Default is C<$!HOME/.config/$cfg-root/Data.d> on *nix systems. Use C<cfgloc-userdata()> to change it.

By default, $cfg-root is set to the basename of your program. This can be changed by calling C<cfg-root()>.

If any of C<$cfgloc-sheet>, C<$cfgloc-set> or C<$cfgloc-userdata> is changed, make sure that it is changed before first time init of B<QA::Types> or otherwise call C<init-dirs(:reset)>! If you want to fall back to the default values after having set them, call the above mentioned methods without argument.

=end pod

#tm:1:instance
method instance ( --> QA::Types ) {
  $instance //= self.bless;

  $instance
}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-load

Load a config or data file into a Hash. There is no use for it directly. To load data, use the modules B<QA::Set> or B<QA::Questionaire>. The type of the file is taken from the $data-file-type.

C<:userdata> is used to load data which will be displayed in the forms.

Only one of the options C<:sheet>, C<:set> or C<:userdata> must be used to load a file. The method throws an exception if none found.

The filenames of any the data files is simple at first. Just a name with an extension depending on its format C<yaml>, C<toml> or C<json>. When versions are used, the name is extended with a version like so C<original-name:version.ext>. Furthermore the name C<original-name:'latest'.ext> is linked to the latest version.

  method qa-load (
    Str:D $qa-filename, :$sheet?, :$set?, :$userdata?, Str :$qa-path?,
    Bool :$!versioned = False, Int :$!version = 0
    --> Hash
  )

=item Str $qa-filename; the filename without the extention. It functions also as the name of the questionaire or set.
=item $sheet; load a sheet if option exists.
=item $set; load a set if option exists.
=item $userdata; load userdata if option exists.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.
=item $versioned; If versioned is True, saving the data with C<.save()> will have a version number added to the filename starting from C<001> with a max of C<999> which should be sufficient. If False, it will take the original and replace the original. To prevent that, use C<.save-as()>.
=item $version; If a version is given, pick that version of the questionaire. If undefined or 0 and $versioned is True, pick the latest version available.

=end pod


#tm:1:qa-load
method qa-load( Str:D $qa-filename, *%options --> Hash ) {
  my Str $basename;
  my Str $qa-path;
  my Str $extension;
  my Bool $user-path = False;

  # If there is a path, use it
  if ?%options<qa-path> {
    $qa-path = %options<qa-path>;
    $user-path = True;
  }

  # Otherwise use one of the defined locations
  else {
    if %options<sheet>:exists {
      $basename = $cfgloc-sheet;
      $extension = 'qst';
    }

    elsif %options<set>:exists {
      $basename = $cfgloc-set;
      $extension = 'set';
    }

    elsif %options<userdata>:exists {
      $basename = $cfgloc-userdata;
      $extension = 'data';
    }

    else {
      die 'No type option found';
    }

    # Define/modify the path
    $qa-path = "$basename/$qa-filename";
  }

  # Check if versions are needed.
  if ?%options<versioned> {
    my Int $version = ?%options<version> ?? %options<version> !! 0;
    if $version > 0 {
      $qa-path ~= $version.fmt(':%03d');
    }

    # if version is 0 (not defined)
    else {
      $qa-path ~= ':latest';
    }
  }

  # Define sub to load a hash from file
  sub load-hash ( Str $path is copy, Sub $loader --> Hash ) {
    my Hash $data;
    if $path.IO.r {
      $data = $loader($path.IO.slurp);
    }

    else {
      # Take original if :latest isn't found
      if $path ~~ m/ ':latest' / {
        $path ~~ s/ ':latest' //;
        $data = $loader($path.IO.slurp);
      }

      elsif $path ~~ m/ ':' \d ** 3 '.' / {
        $path ~~ s/ ':' \d ** 3 '.' //;
        $data = $loader($path.IO.slurp);
      }

      else {
        note "File '$qa-path' not found, an empty Hash is returned";
      }
    }

    $data // %();
  }


  given $data-file-type {
    when QAJSON {
      load-hash(
        $user-path ?? $qa-path !! $qa-path ~ ".json-qa$extension", &from-json
      );
    }

    when QATOML {
      load-hash(
        $user-path ?? $qa-path !!  $qa-path ~ ".toml-qa$extension", &from-toml
      );
    }

    when QAYAML {
      load-hash(
        $user-path ?? $qa-path !!  $qa-path ~ ".yaml-qa$extension", &load-yaml
      );
    }
  }

}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-save

Save a Hash of QA type data into a file. There is no use for it directly. To save data, use the modules B<QA::Set> or B<QAr::Questionaire>.

C<:userdata> is used to save data read from the forms.

Only one of the options C<:sheet>, C<:set> or C<:userdata> can be used. The method throws an exception if none found.

The filenames of any the data files is simple at first. Just a name with an extension depending on its format C<yaml>, C<toml> or C<json>. When versions are used, the name is extended with a version like so C<original-name:version.ext>. Furthermore the name C<original-name:'latest'.ext> is linked to the latest version.

  method qa-save (
    Str:D $qa-filename, Hash:D $qa-data, :$sheet?, :$set?, :$userdata?,
    Str :$qa-path?
    Bool :$!versioned = False
  )

=item Str $qa-filename; the filename without the extention. It functions also as the name of the sheet or set.
=item Hash $qa-data; data.
=item $sheet; load a sheet if option exists.
=item $set; load a set if option exists.
=item $userdata; load userdata if option exists.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.
=item $versioned; If versioned is True, saving the data with C<.save()> will have a version number added to the filename starting from C<001> with a max of C<999> which should be sufficient. If False, it will take the original and replace the original. To prevent that, use C<.save-as()>.
=end pod

#tm:1:qa-save
method qa-save( Str:D $qa-filename, Hash $qa-data, *%options ) {
  my Str $basename = '';
  my Str $qa-path;
  my Str $extension;
  my Bool $user-path = False;

  # If there is a path, use it
  if ?%options<qa-path> {
    $qa-path = %options<qa-path>;
    $user-path = True;
  }

  else {
    if %options<sheet>:exists {
      $basename = $cfgloc-sheet;
      $extension = 'qst';
    }

    elsif %options<set>:exists {
      $basename = $cfgloc-set;
      $extension = 'set';
    }

    elsif %options<userdata>:exists {
      $basename = $cfgloc-userdata;
      $extension = 'data';
    }

    else { die 'No type option found'; }

    # Define/modify the path
    $qa-path = "$basename/$qa-filename";
  }

  # Check if versions are needed.
  $qa-path ~= ':latest' if ?%options<versioned>;

  sub save-hash ( Str $path is copy, Sub $dumper, Hash $data ) {

    # Check if versions are needed. Get the latest version and find out
    # which version it has. Then remove the link, save the data in a higher
    # version and relink to latest version.
    if $path ~~ m/ ':latest' / {
      my Str $fn;

      # First time only original name exists
      if $path.IO.r {
        $fn = $path.IO.resolve.Str;
        $fn ~~ m/ ':' $<version> = \d+ '.' /;
        my Int $version = $<version>.Str + 1;

        $fn = $path;
        $fn.IO.unlink;
        $path ~~ s/ ':latest.' /:$version.fmt('%03d')./;
      }

      else {
        $fn = $path;
        $path ~~ s/ ':latest.' /:001./;
      }

      $path.IO.spurt($dumper($data));
      $path.IO.symlink($fn);
    }

    else {
      $path.IO.spurt($dumper($data));
    }
  }

  given $data-file-type {
    when QAJSON {
      save-hash(
        $user-path ?? $qa-path !!  $qa-path ~ ".json-qa$extension",
        &to-json, $qa-data
      );
    }

    when QATOML {
      save-hash(
        $user-path ?? $qa-path !!  $qa-path ~ ".toml-qa$extension",
        &to-toml, $qa-data
      );
    }

    when QAYAML {
      save-hash(
        $user-path ?? $qa-path !!  $qa-path ~ ".yaml-qa$extension",
        &save-yaml, $qa-data
      );
    }
  }
}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-remove

Remove a Hash of QA type data file. There is no use for it directly. To remove data, use the modules B<QA::Set> or B<QA::Questionaire>.

C<:userdata> is used to save data read from the forms.

Only one of the options C<:sheet>, C<:set> or C<:userdata> can be used. The method throws an exception if none found.

True or False is returned depending on success

  method qa-remove (
    Str:D $qa-filename, :$sheet?, :$set?, :$userdata?, Str :$qa-path
    --> Bool
  )

=item Str $qa-filename; the filename without the extention. It functions also as the name of the sheet or set.
=item $sheet; load a sheet if option exists.
=item $set; load a set if option exists.
=item $userdata; load userdata if option exists.
=item Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.
=end pod

#tm:1:qa-remove
method qa-remove ( Str:D $qa-filename, *%options --> Bool ) {
  my Str $basename = '';
  my Str $qa-path;
  my Str $extension;
  my Bool $user-path = False;

  if ?%options<qa-path> {
    $qa-path = %options<qa-path>;
    $user-path = True;
  }

  else {
    if %options<sheet>:exists {
      $basename = $cfgloc-sheet;
      $extension = 'qst';
    }

    elsif %options<set>:exists {
      $basename = $cfgloc-set;
      $extension = 'set';
    }

    elsif %options<userdata>:exists {
      $basename = $cfgloc-userdata;
      $extension = 'data';
    }

    else { die 'No type option found'; }

    # Define/modify the path
    $qa-path = "$basename/$qa-filename";
  }

  # Check if versions are needed.
  $qa-path ~= ':latest' if ?%options<versioned>;

  given $data-file-type {
    when QAJSON {
      $qa-path = $user-path ?? $qa-path !!  $qa-path ~ ".json-qa$extension";
    }

    when QATOML {
      $qa-path = $user-path ?? $qa-path !!  $qa-path ~ ".toml-qa$extension";
    }

    when QAYAML {
      $qa-path = $user-path ?? $qa-path !!  $qa-path ~ ".yaml-qa$extension";
    }
  }

  my Bool $path-exists = $qa-path.IO.e;
  unlink $qa-path if $path-exists;
  $path-exists
}

#-------------------------------------------------------------------------------
=begin pod
=head2 qa-list

Get the list of sheets, sets or datafiles stored.

Only one of the options C<:sheet>, C<:set> or C<:userdata> can be used. The method throws an exception if none found.

  method qa-list ( :$sheet?, :$set?, :$userdata?, Str :$qa-path --> List )

=item $sheet; load a sheet if option exists.
=item $set; load a set if option exists.
=item $userdata; load userdata if option exists.
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
    else                            { die 'No type option found'; }
  }

  my @qa-list = ();
  for (dir $basename)>>.Str -> $qa-filename is copy {
    # only keep the name of the file without extentions
    $qa-filename ~~ s/ ^ .*? (<-[/]>+ ) \. \w+ $ /$0/;
    @qa-list.push($qa-filename);
  }

  @qa-list
}

#-------------------------------------------------------------------------------
=begin pod
=head2 set-action-handler

set-action-handler is used to set a user defined callback handler. When in a question the action field spec has a value of C<$action-key>, the value of it is used to find the callback. The purpose is to perform some action.

  method set-action-handler (
    Str:D $action-key, Mu:D $handler-object,
    Str $method-name = $action-key,
    Str :$module-name?, Str :$class-name?
    *%options
  )

=item $action-key; the key under which the handler is stored. Also this name is used in the field specification C<action> to refer to the handler to call. The purpose to have a key is to call the same method using different keys and other user options.
=item $handler-object; the object where the handler method resides.
=item $method-name; the name of the handler. This field is optional. When absent the $action-key is used as the method name.
=item $module-name; Optional module name. When method is needed, the module is C<required> and initialized. When initialized the $handler-object is set with the object. This argument is ignored if $handler-object is set to a valid object.
=item $class-name; if classname is given, use that class from the object to initialize
=item %options; any user defined named arguments. These are handed to the method.
=end pod

#tm:1:set-action-handler
method set-action-handler (
  Str:D $action-key, Mu $handler-object is copy = '', Str $method-name? is copy,
  Str :$module-name = '', Str :$class-name = '', *%options
) {
  $method-name = ?$method-name ?? $method-name !! $action-key;

#note "set-action-handler: $action-key, $handler-object, $method-name, $module-name";

  unless $handler-object {
    if ?$module-name {
      try require ::($module-name);
      if ::($module-name) ~~ Failure {
        die "Failed to load $module-name!";
      }

      if ?$class-name {
        $handler-object = ::($class-name).new;
      }

      else {
        $handler-object = ::($module-name).new;
      }
    }

    else {
      die 'No handler object nor module name provided';
    }
  }

  die "Method $method-name not found in provided handler or module {$handler-object.^name}" unless $handler-object.^can($method-name);

  $!user-objects<actions>{$action-key} = [
    $handler-object, $method-name, %options
  ];
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-action-handler

Get the action handler using the C<$action-key>. The method is mostly used by form handling software to call the user handler.

The method returns an array with the following items;
=item $handler-object; the object where the handler method resides.
=item $method-name; the name of the handler
=item %options; any user defined named arguments. These are handed to the method.

  method get-action-handler ( Str:D $action-key --> Array )

=item $action-key; the key under which the handler is stored. Also this name is used in the field specification C<action> to refer to the handler to call.
=end pod

#tm:1:get-action-handler
method get-action-handler ( Str:D $action-key --> Array ) {
  $!user-objects<actions>{$action-key}
}

#-------------------------------------------------------------------------------
=begin pod
=head2 set-check-handler

set-check-handler is used to set a user defined callback handler. When in a question the callback field spec has a value of C<$check-key>, the value of it is used to find the callback. The purpose is to check an input from the sheet.

  method set-check-handler (
    Str:D $check-key, Mu:D $handler-object, Str:D $method-name,
    *%options
  )

=item $check-key; the key under which the handler is stored. Also this name is used in the field specification C<callback> to refer to the handler to call.
=item $handler-object; the object where the handler method resides.
=item $method-name; the name of the handler
=item %options; any user defined named arguments. These are handed to the method.
=end pod

#tm:1:set-check-handler
method set-check-handler (
  Str:D $check-key, Mu:D $handler-object, Str:D $method-name, *%options
) {
  $!user-objects<checks>{$check-key} = [
    $handler-object, $method-name, %options
  ];
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-check-handler

Get the check handler using the C<$check-key>. The method is mostly used by form handling software to call the user handler.

The method returns an array with the following items;
=item $handler-object; the object where the handler method resides.
=item $method-name; the name of the handler
=item %options; any user defined named arguments. These are handed to the method.

  method get-check-handler ( Str:D $check-key --> Array )

=end pod

#tm:1:get-check-handler
method get-check-handler ( Str:D $check-key --> Array ) {
  $!user-objects<checks>{$check-key}
}

#-------------------------------------------------------------------------------
=begin pod
=head2 set-widget-object

Store a user defined input widget using the C<$widget-key>.
The provided C<$widget-object> must conform to some rules like any other input widget in this system. The rules are;

=item Use the B<QA::Gui::Value role>.
=item Have method C<init-widget()>.
=item Have method C<create-widget()>.
=item Have method C<get-value()>.
=item Have method C<set-value()>.
=item Optionally have C<check-value()>.
=begin item
Have a signal registered so it can respond to user input or focus changes.
=end item
B< >

  method set-widget-object (
    Str:D $widget-key, Mu:D $widget-object
  )

=item $widget-key; the key under which the widget is stored. Also this name is used in the field specification C<userwidget> to refer to this widget.
=item $widget-object; the input widget

An example widget could be something like the one shown below. This widget shows a button with a number as its label. This label is incremented when the button is pressed.

  class MyWidget does QA::Gui::Value {

    method init-widget (
      QA::Question:D :$!question, Hash:D :$!user-data-set-part
    ) {

      # widget is not repeatable
      $!question.repeatable = False;
    }

    method create-widget ( Str $widget-name, Int $row --> Any ) {

      # create a text input widget
      my Gnome::Gtk3::Button $button .= new;
      $button.set-label('0');
      $button.set-hexpand(False);
      $button.register-signal( self, 'change-label', 'clicked');

      $button
    }

    method get-value ( $button --> Any ) {
      $button.get-label;
    }

    method set-value ( Any:D $button, $label ) {
      $button.set-label($label);
    }

    method change-label ( :_widget($button) ) {
      $button.set-label(($button.get-label // '0').Int + 1);

      my ( $n, $row ) = $button.get-name.split(':');
      $row .= Int;
      self.process-widget-input( $button, $row, :!do-check);
    }
  }

  # init ...
  my QA::Types $qa-types .= instance;
  $qa-types.set-widget-object( 'my-widget', MyWidget.new);


=end pod

#tm:1:set-widget-object
method set-widget-object ( Str:D $widget-key, Mu:D $widget-object ) {
  $!user-objects<widgets>{$widget-key} = $widget-object;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-widget-object

Get the widget object using the C<$widget-key>. The method is mostly used by form handling software to display and use the input widget.

  method get-widget-object ( Str:D $widget-key --> Any )

=end pod

#tm:1:get-widget-object
method get-widget-object ( Str:D $widget-key --> Any ) {
  $!user-objects<widgets>{$widget-key}
}

#-------------------------------------------------------------------------------
# See also https://stackoverflow.com/questions/43853548/xdg-basedir-directories-for-windows

=begin pod
=head2 init-dirs

When config or data directories are changed after the initialization of B<QA::Types>, this call is needed to prepare the directories. When $reset is C<True>, the directories are reset to default values.

  method init-dirs ( Bool :$reset = False )

=end pod

#tm:1:reinit:
method init-dirs ( Bool :$reset = False ) {
  self.setup-path(:$reset);

  mkdir( $cfgloc-userdata, 0o760) unless $cfgloc-userdata.IO.d;
  mkdir( $cfgloc-set, 0o760) unless $cfgloc-set.IO.d;
  mkdir( $cfgloc-sheet, 0o760) unless $cfgloc-sheet.IO.d;
}

#-------------------------------------------------------------------------------
method list-dirs ( --> List ) {
  self.setup-path;
  ( $cfgloc-userdata, $cfgloc-set, $cfgloc-sheet)
}

#-------------------------------------------------------------------------------
method setup-path ( Bool :$reset = False ) {
  if $reset {
    if $*DISTRO.is-win {
      $cfgloc-sheet = "$*HOME/dataDir/$cfg-root/Qsts";
      $cfgloc-set = "$*HOME/dataDir/$cfg-root/Sets";
      $cfgloc-userdata = "$*HOME/dataDir/$cfg-root/Data";
    }

    else {
      $cfgloc-sheet = "$*HOME/.config/$cfg-root/Qsts.d";
      $cfgloc-set = "$*HOME/.config/$cfg-root/Sets.d";
      $cfgloc-userdata = "$*HOME/.config/$cfg-root/Data.d";
    }
  }

  else {
    if $*DISTRO.is-win {
      $cfgloc-sheet //= "$*HOME/dataDir/$cfg-root/Qsts";
      $cfgloc-set //= "$*HOME/dataDir/$cfg-root/Sets";
      $cfgloc-userdata //= "$*HOME/dataDir/$cfg-root/Data";
    }

    else {
      $cfgloc-sheet //= "$*HOME/.config/$cfg-root/Qsts.d";
      $cfgloc-set //= "$*HOME/.config/$cfg-root/Sets.d";
      $cfgloc-userdata //= "$*HOME/.config/$cfg-root/Data.d";
    }
  }
}
