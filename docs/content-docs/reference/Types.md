A singleton class to provide types, global variables and some routines.

Types
=====

QAFieldType
-----------

QAFieldType is an enumeration of field types to provide an anwer. The types are (and more to come);

  * QACheckButton; A group of checkbuttons.

  * QAComboBox; A pulldown list with items.

  * QAEntry; A single line of text.

  * QAFileChooser; A button to open a file dialog and choose a file.

  * QAImage; A button to open a file dialog and choose an image.

  * QARadioButton; A group of radiobuttons.

  * QAScale; A scale for numeric input.

  * QASpinButton; A spinbutton for numeric input.

  * QASwitch; On/Off, Yes/No kind of input.

  * QATextView; Multi line input.

  * QAToggleButton; Like switch.

  * QAUserWidget; A user widget. The key is given with userwidget.

Page types are based on GtkAssistantPageType

  * QAContent; The page has regular contents. This is the default page type in all of the display posibilities.

  * QAIntro; The page contains an introduction to the assistant task. This could be displayed on the first tab of a Notebook, Stack or Assistant. There is no use for it in a Dialog because only one page is shown.

  * QAConfirm; The page lets the user confirm or deny the changes. Only useful in an Assistant.

  * QASummary; The page informs the user of the changes done. Only useful in an Assistant.

  * QAProgress; Used for tasks that take a long time to complete, blocks the assistant until the page is marked as complete. Only useful in an Assistant.

QAGridColSpec
-------------

Column numbers for the question-answer row in a grid

  * QAQuestion;

  * QARequired;

  * QAAnswer;

AGridColSpec
------------

Column numbers for the grid in the answer part of the QA

  * QACatColumn;

  * QAInputColumn;

  * QAButtonColumn;

Methods
=======

new
---

The class is a singleton class where `.new()` is prevented to be used. The call will throw an exception. To get the object, call `.instance()`.

instance
--------

The users application can modify the variables before opening any query sheets. The following variables are used in this program;

  * QADataFileType `$data-file-type`; You can choose from QAJSON or QATOML. By default it loads and saves the answers to questions in json formatted files.

  * Str `$cfgloc-set`; Location where sets are stored. Default is `$!HOME/.config/QAManager/Sets.d` on *nix systems. Use `cfgloc-set()` to change it.

  * Str `$cfgloc-sheet`; Location where sheets are stored. Default is `$!HOME/.config/QAManager/Sheets.d` on *nix systems. Use `cfgloc-sheet()` to change it.

  * Str `$cfgloc-userdata`; Location where userdata is stored. Default is `$!HOME/.config/<modified $*PROGRAM-NAME>` on *nix systems. Use `cfgloc-userdata()` to change it.

If any of `$cfgloc-sheet`, `$cfgloc-set` or `$cfgloc-userdata` is changed, make sure that it is changed before first time init of **QA::Types** or otherwise call `reinit-dirs()`! If you want to fall back to the default values after having set them, call the above mentioned methods with an undefined string, i.e. Str, like e.g. `cfgloc-sheet(Str)`.

qa-load
-------

Load a config or data file into a Hash. There is no use for it directly. To load data, use the modules **QManager::Set** or **QManager::Sheet**. The type of the file is taken from the $data-file-type.

`:userdata` is used to load data which will be displayed in the forms.

Only one of the options `:sheet`, `:set` or `:userdata` must be used to load a file. The method throws an exception if none found.

    method qa-load (
      Str:D $qa-filename, :$sheet?, :$set?, :$userdata?, Str :$qa-path?
      --> Hash
    )

  * Str $qa-filename; the filename without the extention. It functions also as the name of the sheet or set.

  * $sheet; load a sheet if option exists.

  * $set; load a set if option exists.

  * $userdata; load userdata if option exists.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.

qa-save
-------

Save a Hash of QA type data into a file. There is no use for it directly. To save data, use the modules **QManager::Set** or **QManager::Sheet**.

`:userdata` is used to save data read from the forms.

Only one of the options `:sheet`, `:set` or `:userdata` can be used. The method throws an exception if none found.

    method qa-save (
      Str:D $qa-filename, Hash:D $qa-data, :$sheet?, :$set?, :$userdata?,
      Str :$qa-path?
    )

  * Str $qa-filename; the filename without the extention. It functions also as the name of the sheet or set.

  * Hash $qa-data; data.

  * $sheet; load a sheet if option exists.

  * $set; load a set if option exists.

  * $userdata; load userdata if option exists.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.

qa-remove
---------

Remove a Hash of QA type data file. There is no use for it directly. To remove data, use the modules **QManager::Set** or **QManager::Sheet**.

`:userdata` is used to save data read from the forms.

Only one of the options `:sheet`, `:set` or `:userdata` can be used. The method throws an exception if none found.

    method qa-remove (
      Str:D $qa-filename, :$sheet?, :$set?, :$userdata?, Str :$qa-path
    )

  * Str $qa-filename; the filename without the extention. It functions also as the name of the sheet or set.

  * $sheet; load a sheet if option exists.

  * $set; load a set if option exists.

  * $userdata; load userdata if option exists.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and other options are then ignored.

qa-list
-------

Get the list of sheets, sets or datafiles stored.

Only one of the options `:sheet`, `:set` or `:userdata` can be used. The method throws an exception if none found.

    method qa-list ( :$sheet?, :$set?, :$userdata?, Str :$qa-path --> List )

  * $sheet; load a sheet if option exists.

  * $set; load a set if option exists.

  * $userdata; load userdata if option exists.

  * Str $qa-path; optional path to locate the file. The value of $sheet is then ignored.

set-action-handler
------------------

set-action-handler is used to set a user defined callback handler. When in a question the action field spec has a value of `$action-key`, the value of it is used to find the callback. The purpose is to perform some action.

    method set-action-handler (
      Str:D $action-key, Mu:D $handler-object, Str:D $method-name,
      *%options
    )

  * $action-key; the key under which the handler is stored. Also this name is used in the field specification `action` to refer to the handler to call.

  * $handler-object; the object where the handler method resides.

  * $method-name; the name of the handler

  * %options; any user defined named arguments. These are handed to the method.

get-action-handler
------------------

Get the action handler using the `$action-key`. The method is mostly used by form handling software to call the user handler.

The method returns an array with the following items;

  * $handler-object; the object where the handler method resides.

  * $method-name; the name of the handler

  * %options; any user defined named arguments. These are handed to the method.

    method get-action-handler ( Str:D $action-key --> Array )

  * $action-key; the key under which the handler is stored. Also this name is used in the field specification `action` to refer to the handler to call.

set-check-handler
-----------------

set-check-handler is used to set a user defined callback handler. When in a question the callback field spec has a value of `$check-key`, the value of it is used to find the callback. The purpose is to check an input from the sheet.

    method set-check-handler (
      Str:D $check-key, Mu:D $handler-object, Str:D $method-name,
      *%options
    )

  * $check-key; the key under which the handler is stored. Also this name is used in the field specification `callback` to refer to the handler to call.

  * $handler-object; the object where the handler method resides.

  * $method-name; the name of the handler

  * %options; any user defined named arguments. These are handed to the method.

get-check-handler
-----------------

Get the check handler using the `$check-key`. The method is mostly used by form handling software to call the user handler.

The method returns an array with the following items;

  * $handler-object; the object where the handler method resides.

  * $method-name; the name of the handler

  * %options; any user defined named arguments. These are handed to the method.

    method get-check-handler ( Str:D $check-key --> Array )

set-widget-object
-----------------

Store a user defined input widget using the `$widget-key`. The provided `$widget-object` must conform to some rules like any other input widget in this system. The rules are;

  * Use the **QA::Gui::Value role**.

  * Have method `init-widget()`.

  * Have method `create-widget()`.

  * Have method `get-value()`.

  * Have method `set-value()`.

  * Optionally have `check-value()`.

  * Have a signal registered so it can respond to user input or focus changes.

****

    method set-widget-object (
      Str:D $widget-key, Mu:D $widget-object
    )

  * $widget-key; the key under which the widget is stored. Also this name is used in the field specification `userwidget` to refer to this widget.

  * $widget-object; the input widget

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

      method change-label ( Gnome::Gtk3::Button() :_native-object($button) ) {
        $button.set-label(($button.get-label // '0').Int + 1);

        my ( $n, $row ) = $button.get-name.split(':');
        $row .= Int;
        self.process-widget-input( $button, $row, :!do-check);
      }
    }

    # later ...
    my QA::Types $qa-types .= instance;
    $qa-types.set-widget-object( 'my-widget', MyWidget.new);

get-widget-object
-----------------

Get the widget object using the `$widget-key`. The method is mostly used by form handling software to display and use the input widget.

    method get-widget-object ( Str:D $widget-key --> Any )

reinit-dirs
-----------

When config or data directories are changed after the initialization of **QA::Types**, this call is needed to prepare the directories.

    method reinit-dirs ( )
