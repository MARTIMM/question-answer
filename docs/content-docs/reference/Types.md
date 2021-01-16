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

set-handler
-----------

set-handler is used to set a user defined callback handler. When in a question the callback specification is used, the value of it is used to find the callback. Callbacks can have one of two purposes. First is to check an input from the sheet. Second is to perform some action (this is not implemented yet).

    method set-action-handler (
      Str:D $callback-key, Mu:D $handler-object, Str:D $method-name,
      *%options
    )

    method set-check-handler (
      Str:D $callback-key, Mu:D $handler-object, Str:D $method-name,
      *%options
    )

