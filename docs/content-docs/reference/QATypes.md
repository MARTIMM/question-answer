A singleton class to provide types, global variables and some routines.

Types
=====

QAFieldType
-----------

QAFieldType is an enumeration of field types to provide an anwer. The types are (and more to come);

  * QACheckButton; A group of checkbuttons.

  * QAComboBox; A pulldown list with items.

  * QAEntry; A single line of text.

  * QARadioButton; A group of radiobuttons.

  * QAScale; A scale for numeric input.

  * QASwitch; On/Off, Yes/No kind of input.

  * QATextView; Multy line input.

  * QAToggleButton; Like switch.

Methods
=======

new
---

The class is a singleton class where `.new()` is prevented to be used. The call will throw an exception. To get the object, call `.instance()`.

instance
--------

The application can modify the variables before opening any query sheets.

The following variables are used in this program;

  * QADataFileType `$!data-file-type`; You can choose from INI, JSON or TOML. By default it saves the answers in json formatted files.

  * Hash `$!callback-objects`; User defined callback handlers. The `$!callback-objects` have two toplevel keys, `actions` to specify action like callbacks and `checks` to have callbacks for checking the input data. The next level is a name which is defined along a question/answer entry. The value of that name key is an array. The first value is the handler object, the second is the method name, the rest are obtional pairs of values which are also provided to the method. The manager will also add some parameters to the method.

Summarized

    $!callback-objects = %(
        actions => %(
          user-key => [ $handler-object, $method-name, :myval1($val1), ...],
          ...
        ),
        checks => %(
          user-key => [ $handler-object, $method-name, :myval1($val1), ...],
          ...
        ),
      );

See also subroutine `set-handler()`.

  * Str `$!cfgloc-category`; Location where categories are stored. Default is `$!HOME/.config/QAManager/Categories.d` on *nix systems.

  * Str `$!cfgloc-sheet`; Location where sheets are stored. Default is `$!HOME/.config/QAManager/Sheets.d` on *nix systems.

  * Str `$!cfgloc-resource`; Location where sheets are stored or retrieved from a resources directory for your application. Default is `./resources/Sheets` on *nix systems.

If any of `$!cfgloc-category`, `$!cfgloc-sheet` or `$!cfgloc-resource` is changed, make sure that the directories exists!

qa-path
-------

Return a path where a QA based sheet or category should be found.

    method qa-path( Str:D $qa-filename, Bool :$sheet --> Str )

  * Str $qa-filename; the filename for the category or sheet.

  * Bool $sheet; switch between sheet or category.

qa-load
-------

Load a JSON QA based sheet or category file into a Hash. There is no use for it directly. To load data, use the modules **QManager::Category** or **QManager::Sheet**.

    method qa-load (
      Str $qa-filename = '__zzz__', Bool :$sheet = False, Str :$qa-path --> Hash
    )

  * Str $qa-filename; the filename for the category or sheet.

  * Bool $sheet; switch between sheet or category.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and $sheet are then ignored.

qa-save
-------

Save a Hash of QA type data into a file. There is no use for it directly. To save data, use the modules **QManager::Category** or **QManager::Sheet**.

    method qa-save (
      Str $qa-filename = '__zzz__', Hash $qa-data = %(),
      Bool :$sheet = False, Str :$qa-path
    )

  * Str $qa-filename; the filename for the category or sheet.

  * Hash $qa-data; sheet or category data.

  * Bool $sheet; switch between sheet or category.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and $sheet are then ignored.

qa-remove
---------

Remove a QA type data file. There is no use for it directly. To remove data, use the modules **QManager::Category** or **QManager::Sheet**.

    method qa-remove (
      Str $qa-filename = '__zzz__', Bool :$sheet = False,
      Str :$qa-path
    )

  * Str $qa-filename; the filename for the category or sheet.

  * Bool $sheet; switch between sheet or category.

  * Str $qa-path; optional path to locate the file. The values of $qa-filename and $sheet are then ignored.

qa-list
-------

Get the list of sheets or categories stored.

    method qa-list ( Bool :$sheet = False, Str :$qa-path --> List )

  * Bool $sheet; switch between sheet or category.

  * Str $qa-path; optional path to locate the file. The value of $sheet is then ignored.

