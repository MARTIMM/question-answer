[toc]

# Packages

Basically there are two packages made for the questions and answer system. The first, called **QA**, is meant to define the primary modules which helps the user to load a questionare and displays it on screen. The resulting answers are returned and optionally saved at the users preferred location. The other package, **QA::Manager** helps the user to describe a questionnaire and to save it for use in an application.

## QA

## QA::Manager

### Management of questionnaires.

The manager helps to create sets of questions and are stored in the managers environment. These sets are combined into pages and the pages comprise the questionnaire. The questionnaire is stored at user desirable location.

The manager needs to ask questions to create the sets and pages. For this, the program has several questionnaires of its own.

The locations of the user defined sets and the questionnaires used by the manager are stored the desktop configurations directory
* `$HOME/.config/io.github.martimm.qa-manager`
  * `Sets`
  * `Questionnaires`
  * `QA`


# Manager API

## Main window
The main window has a menu with the following menu items.
* `File`
  * `Configure`; Display configuration window
  * `Quit`; Stop the program

* `Questionnaire`
  * `New`; Show a dialog with a few questions to create a new questionnaire.
  * `Modify`; Change the info for the page.
  * `Save`; Save questionnaire in managers environment.
  * `Load`; Load the questionnare. Only the ones in the managers environment can be loaded.
  * `Export`; Place the questionnaire where user wants it.
  * `View`; Display the questionnaire for testing.

* `Pages`
  * `New`; Show a dialog with a few questions for the new page.
  * `Add`; Select a page to add to the questionnaire.
  * `Remove`; Show a dialog to remove a specific page from the questionnaire.

* `Sets`
  * `New`; Create a new set of questions.
  * `Add`; Add a question.
  * `Save`; Save the set in managers environment.

* `Help`
  * `About`; Show a dialog with program version, license and author.

Below the menubar, there are a few input fields;
* A combobox with the page names for the questionnaire.
* a listbox is shown with the names of previously saved sets. From these sets, a page can be constructed.



## Defining a question

* Create questions
```
my QAManager::Question $un .= new(:name<username>, :qa-data(%(...)));
$un.required = True;

my QAManager::Question $pw .= new(:name<password>, :qa-data(%(...)));
$un.required = True;
$un.encode = True;
```

## Defining a set of questions

* Add questions to a set
```
my QAManager::Set $creds .= new(:name<credentials>);
$creds.add-question($un);
$creds.add-question($pw);
```

<!--
## Building a category(or archive) of sets

* Create a category, populate and save
```
my QAManager::Category $category .= new(:category('accounting'));
$category.add-set($creds);
$category.save;
```
* Remove a category
```
$category.remove
```
-->

## Building a sheet
* Create a sheet, populate and save
```
my QAManager::Sheet $sheet .= new(:sheet('login'));
$sheet.display = QADialog;
$sheet.add-page( :title<Login>, :description('MongoDB Server Login');
$sheet.add-set( :category<accounting>, :set<credentials>);
$sheet.save;
```
<!--
## Run QA Dialog
* Select a sheet and run invoice dialog
```
my $callback-handlers = class { method x ( ... ) { ... } }.new;
my QAManager $qam .= new;
my Hash $data = $qam.run-invoice( :sheet<Login>, :$callback-handlers, :!save);
if ?$data { ... }
```
-->

<!--
# QA Manager
Main display
* [x] Title
* [x] Menu
  * [x] File
    * [ ] Quit; Quit program. Test for edit in progress

  * [x] Sheet (visible when Sheets notebook page is selected)
    * [ ] New
    * [ ] Open
    * [ ] Save
    * [ ] Save As
    * [ ] Delete

  * [ ] Category (visible when Categories notebook page is selected)
    * [ ] Open
    * [ ] Close
    * [ ] Save
    * [ ] Delete

  * [x] Set (visible when Sets notebook page is selected)
    * [ ] New
    * [ ] Add QA
    * [ ] Delete QA
    * [ ] Save
    * [ ] Delete

  * [x] Help
    * [ ] Purpose
    * [ ] Index
    * [ ] About

* [x] Notebook pages
  * [x] Sheets
    * [ ] Display a TreeView using a TreeStore model of available sheets with pages and sets.

  * [x] Categories
    * [ ] Shows a list of categories on the left. The right side is for two set lists. In between the set lists there are two arrow buttons.
      When lists are filled using open from menu, a set can be selected and moved from one list to the other using the arrow buttons.
      * [ ] First open from menu displayes a list of sets on the left from a selected category.
      * [ ] Second open from menu displayes a list of sets on the right from a selected category.

      * [ ] Close from menu closes the selected category
      * [ ] Save from menu save the changes on disk
      * [ ] Delete from menu deletes the category

  * [x] Sets
    * [x] Display a TreeView using a TreeStore model of available categories with the defined sets and QA entries.
      * [ ] New will create a new set. A dialog is shown with specific set questions. After finishing the dialog, the set is inserted in the set list without QA entries.
      * [ ] Add QA will show a dialog where a QA entry can be specified. After closing the dialog, the entry will be visible in the tree view.
      * [ ] Select a QA entry and keyboard arrow up/down will move the QA entry up or down the list.
      * [ ] Select a QA entry and delete from menu will remove the QA entry.
      * [ ] Save the set in the category on disk with menu save.

* Dialogs
  * [ ] Display of a QA content with two buttons to cancel or save.
  * [ ] Message dialog for several informational messages or warnings with close button.
  * [ ] Dialog to show help content with close button.
  * [ ] About dialog to show the program info and version with close button.
-->


# Display and behavior of sheet types

All but the Assistant sheet type are displayed in a Dialog widget. In this widget there can be one of several possibilities to give a it a specific layout.

There is a possibility to name the buttons differently. This is done using a button map. Each key in this map has by default the same button label as its key but the first letter of each word uppercase and the rest lowercase. E.g. `:cancel<Cancel>` and `:save-quit<Save Quit>`. You might want to set `:cancel<Quit>` or `:save-quit<Login>`.

## Display grid of a question

* Grid row
  * Grid col 0 (QAQuestion): Label with question.
  * Grid col 1 (QARequired): Label with optional star (**\***) if answer is required.
  * Grid col 2 (QAAnswer): A structure wherein the input widget resides
    * Frame; border is made visible when multiple answers are set (repeatable). Its widget name will be set to the name of the question.
      * Grid; mostly one row. more rows when repeatable.
        * Grid col 0 (QACatColumn): A ComboBox when repeatable and selectlist are set.
        * Grid col 1 (QAInputColumn): An input widget. Its widget name is that of the questions name with the row number attached, separated by a colon (**:**).
        * Grid col 2 (QAButtonColumn): A + or - button to add a row or to delete the row. Only shown when repeatable is set.

## Behavior of any input sheet type

The diagram shows a displayed sheet state where some of the input fields can be checked for wrong or absent answers. A button press will move the situation to other states depending on the sheet display type. Some of the buttons will return to the input state.

hide empty description

state "user app" as u: user prepares pages
state "initializing" as i: load sheet and user data
state "displayed page" as dp: answer questions
state "processing" as ip

[*] --> u

u -> i: call sheet\ndialog
i --> dp: display\npages

dp --> check: change\nfocus
check: string value check
check -> dp: modify field display\nand set statusbar
dp --> ip: some button\npress
ip -> u: quit or\nsave-quit
ip -> dp: continue\ninput
u --> [*]



## QADialog sheet type

 This is the simplest of cases. There will be no extra pages and if given a sheet with more than one page, it will only handle the first page and ignore the rest. The dialog shows two buttons; `Cancel` or `save-quit`.

hide empty description

skinparam DefaultFontSize 17
skinparam DefaultFontName "z003"
'skinparam StateMessageAlignment left
'skinparam DefaultTextAlignment middle
skinparam StateStartColor #a0a0a0
'skinparam StateAttributeFontColor
'skinparam StateAttributeFontName
'skinparam StateAttributeFontSize
'skinparam StateAttributeFontStyle
'skinparam StateBackgroundColor
'skinparam StateBorderColor
skinparam StateEndColor #a0a0a0
'skinparam StateFontColor
'skinparam StateFontName
'skinparam StateFontSize
'skinparam StateFontStyle

state "displayed page" as dp: answer questions
state "final check" as fc: check answers
state "wrong" as w: show problem message dialog
state "are you sure" as c: show quit message dialog

[*] --> dp
dp --> c: cancel\npressed
dp --> fc: save-quit\npressed
fc --> w: wrong\nshow\nmessage
w --> dp: want to\ncontinue
w --> [*]: want to\nquit
fc --> finished: ok\nsave-quit

c --> dp: want to\ncontinue
c --> [*]: want to\nquit
finished --> [*]
finished: save data if requested



## QANotebook sheet type

A QANotebook has more pages selectable by tabs. There might be an introductory page with a description of the questionnaire and no questions. There is only a `Cancel` button on an intro-page. Other buttons are disabled or invisible. The pages with questions have a `Cancel` and a `save-quit` button.

hide empty description

skinparam DefaultFontSize 17
skinparam DefaultFontName "z003"
skinparam StateStartColor #a0a0a0
skinparam StateEndColor #a0a0a0

state "displayed intro" as dpi: show purpose of this QA
state "displayed content" as dpc: answer questions
state "final check" as fc: check answers
state "wrong" as w: show problem message dialog
state "are you sure" as c: show quit message dialog

[*] --> dpi
[*] --> dpc
dpi --> dpc: tab\nselected
dpc --> dpi: tab\nselected
dpc --> dpc: tab selected\nswitch page

dpc --> fc: save-quit\npressed
fc --> w: wrong\nshow\nmessage
w --> dpc: want to\ncontinue
w --> [*]: want to\nquit
fc --> finished: ok

dpi --> c: cancel\npressed
dpc --> c: cancel\npressed
c --> dpc: want to\ncontinue
c --> dpi: want to\ncontinue
c --> [*]: want to\nquit
finished --> [*]
finished: save data if requested







'dpc --> canceled: cancel\npressed
'dpc --> finished: save-quit\npressed

'canceled --> [*]
'finished --> [*]
'finished: save data\nif requested




# UML Diagrams

<!--
## Overall view
```plantuml
scale 0.9
skinparam packageStyle rectangle
skinparam stereotypeCBackgroundColor #80ffff
set namespaceSeparator ::
hide empty members

'Class and interface decorations
Interface QA::Gui::PageTools <Interface>
class QA::Gui::PageTools <<(R,#80ffff)>>

'Connections

UserApp *-up-> QA::Gui::PageSimpleDialog
QA::Gui::Dialog <|-- QA::Gui::PageSimpleDialog
QA::Gui::PageTools <|.. QA::Gui::PageSimpleDialog
Gnome::Gtk4::Dialog <|-- QA::Gui::Dialog

QA::Gui::PageSimpleDialog *-> "*" QA::Gui::Page
QA::Gui::Page *-> "*" QA::Gui::Set
QA::Gui::Set *-right-> "*" QA::Gui::Question
QA::Gui::Question *-right-> QA::Gui::InputWidget
```
The **QA::Gui::PageSimpleDialog** module can be replaced with **QA::Gui::SheetSimpleWindow** **QA::Gui::PageStackDialog**, **QA::Gui::SheetNotebook** or **QA::Gui::SheetAssistant** depending on the purpose of the questionnaire.
-->



## Input widget details
```plantuml
scale 0.9
skinparam packageStyle rectangle
skinparam stereotypeCBackgroundColor #80ffff
skinparam groupInheritance 2
set namespaceSeparator ::
hide empty members

'Class and interface decorations

Interface QA::Gui::Value <Interface>
class QA::Gui::Value <<(R,#80ffff)>> {
  +process-widget-input()
  +check-widget-value()
  +check-users-action()
  +run-users-action()
  +set-status-hint()
  +add-class()
  +remove-class()
  -adjust-user-data()
  {abstract} set-value()
  {abstract} create-widget()
'  {abstract} clear-value()
  {abstract} input-change-handler()
}

class QA::Gui::InputWidget {
  QA::Question $!question
  Hash $!user-data-set-part
'  Array $!values
  Gnome::Gtk4::Widget $!widget-object
  Array $!grid-row-data
  Gnome::Gtk4::Grid $!grid
  Bool $.faulty-state;

  !create-widget-object()
  !create-user-widget-object()
  !append-grid-row()
  !create-toolbutton()
  !create-combobox()
  !apply-values()

  add-row()
  delete-row()
  hide-tb-add()
}


class QA::Gui::AnInputWidget <input widget> {

}


class QA::Gui::Question {
  +Hash $.pages;
  +Hash $.sets;
  +Hash $.questions;
}


class QA::Gui::PageTools <<(R,#80ffff)>>
Interface QA::Gui::PageTools <Interface>



'Connections

QA::Gui::Value <|... QA::Gui::AnInputWidget
QA::Gui::Value --> QA::Gui::InputWidget
QA::Gui::Value ---> QA::Gui::Question
QA::Gui::Value -> "user-data"
QA::Gui::InputWidget *-up--> QA::Gui::AnInputWidget
QA::Gui::Question *-> QA::Gui::InputWidget
'QA::Gui::InputWidget *-> QA::Question: $!question
QA::Gui::Value --> QA::Question: $!question

QA::Gui::PageTools --> QA::Gui::Page
QA::Gui::PageSimpleWindow ..|> QA::Gui::PageTools
QA::Gui::PageStackWindow ..|> QA::Gui::PageTools
QA::Gui::PageNotebookWindow ..|> QA::Gui::PageTools

QA::Gui::Question -UP-> "*" QA::Gui::Page: $.pages
QA::Gui::Page --> "*" QA::Gui::Set: $.sets
QA::Gui::Set -> "*" QA::Gui::Question: $.questions
'QA::Gui::Set "*" <-* QA::Gui::Question: $.sets
'QA::Gui::Question "*" <-* QA::Gui::Question

'QA::Gui::InputWidget -up--> QA::Gui::QACheckButton
'QA::Gui::InputWidget -up--> QA::Gui::QAComboBox
'QA::Gui::InputWidget -up--> QA::Gui::QAEntry
'QA::Gui::InputWidget -up--> QA::Gui::QAFileChooser
'QA::Gui::InputWidget -up--> QA::Gui::QAImage
'QA::Gui::InputWidget -up--> QA::Gui::QARadioButton
'QA::Gui::InputWidget -up--> QA::Gui::QASpinButton
'QA::Gui::InputWidget -up--> QA::Gui::QASwitch
'QA::Gui::InputWidget -up--> QA::Gui::QATextView

'QA::Gui::Value <|... QA::Gui::QACheckButton
'QA::Gui::Value <|... QA::Gui::QAComboBox
'QA::Gui::Value <|... QA::Gui::QAEntry
'QA::Gui::Value <|... QA::Gui::QAFileChooser
'QA::Gui::Value <|... QA::Gui::QAImage
'QA::Gui::Value <|... QA::Gui::QARadioButton
'QA::Gui::Value <|... QA::Gui::QASpinButton
'QA::Gui::Value <|... QA::Gui::QASwitch
'QA::Gui::Value <|... QA::Gui::QATextView
```
