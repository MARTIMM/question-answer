---
title: About MongoDB Driver
nav_menu: default-nav
sidebar_menu: about-sidebar
layout: sidebar
---
# Release notes

See [semantic versioning](http://semver.org/). Please note point 4. on that page: **_Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable._**

#### 2021-04-24 0.14.5
* Improved **QA::Gui::Value** and other QA widgets by adding class names. Names are like QAEntry and QAFrame.
* Bugfixed **QA::Gui::Value**; returned data from repeatable input fields were extended with an empty value each time.
<!--
* Label holding question can have Pango markup.
-->

#### 2021-03-16 0.14.4
* META6 bugfix. Missing a resource.

#### 2021-03-16 0.14.3
* Add `.cfg-root()` to **QA::Types**. Also not store anymore in QAManager environment. By default only in program config or in a root set by cfg-root(). Also tried to set dirs specific for windows using `$*HOME/dataDir`.
* Bugfixes.
  * Name fields of sets and pages where not changed everywhere. It is now `set-name` and `page-name` resp.
  * `QA::Gui::Value.add-row()` must also push an empty value on the users array.

#### 2021-01-15 0.14.2
* Remove `Category` module, directories, etc. and replace it with a series of `Set` files in a set directory.
* Rewrite several functions in QATypes module.
* Changed module Set to save and load set files.
* Changed module Sheet to cope with new layout.

#### 2021-01-14 0.14.1
* Bugfix in QARadioButton
* Splitup code from `SheetDialog.pm6` to keep modules smaller and `SheetDialog.raku` to make separate demo programs.

#### 2020-12-08 0.14.0
* The questions field type `encode` is removed. It felt that it should be the users responsibility what to do with their text input. Basically it was meant to return a secret, like passwords, encoded.
* Added an `action` field type. Like `callback` it refers to a callable users routine to be executed after the value was entered and checked on its value. The action routine returns an Array of Hashes which describes what to do further. This could be something like enabling or disabling a button.
* `QAOtherUserAction` return from user action is implemented.

#### 2020-12-06 0.13.1
* Split package into two. Now called **QA** and **QA::Manager**. **QA** is meant for using the forms by a user's application while **QA::Manager** is meant to create and manage these forms. A separation of the two makes the most used one, **QA**, somewhat lighter. Both packages wil continue their versions at 0.13.1. The [website is now at](https://martimm.github.io/question-answer/)

#### 2020-11-18 0.13.0
* Add **QAManager::Gui::QASpinButton** for type QASpinButton.

#### 2020-10-27 0.12.1
* Added two named arguments to `.new()` of **QAManager::Gui::SheetDialog**.
  * :show-cancel-warning to prevent a dialog with an 'are you sure?' message.
  * :save-data to store the data on disk or not. It is read if there is any.

#### 2020-10-27 0.12.0
* User definable input field widgets are now possible to use. The type used is `QAUserWidget` and used question parameter is `userwidget`. Userwidget is a key pointing to a previously created object stored with method `.set-widget-object()` found in module QATypes.
* Type QARadioButton, QACheckButton input fields added.

#### 2020-10-24 0.11.0
* Add QAComboBox, QASwitch, QAFileChooser, QAImage input fields

#### 2020-10-20 0.10.0
* Add QATextView input field
* Finished work on QAEntry input field and the role **QAManager::Gui::Value** extended with general tests.

#### 2020-10-15 0.9.0
* Add Statusbar module to show up at the bottom of sheet dialogs

#### 2020-10-11 0.8.1
* Dialog is kept visible when errors are still there. Also a message dialog is shown telling about the error.
* An optional 'are you sure' message is shown on Cancel. When yes is clicked, the dialog is closed.

#### 2020-10-10 0.8.0
* Sheet dialog is getting its form
  * QANotebook representation implemented
  * OAEntry is implemented
  * Values from user config loaded and filled in sheet
  * Check on required and user implemented checks on input using callback
  * Values from form saved when no errors are found
  * Button labels can be renamed on dialog
* Todo
  * Other representations must be implemented
  * Other field types must be implemented
  * Show message dialogs when input error is found
  * Dialog must be kept visible when errors are still there
  * An optional 'are you sure' message must be shown on Cancel

#### 2020-09-15 0.7.1
* Renames
  * KV into Question together with some of the methods.
  * ValueRepr to Value
  * EntryFrame to QAEntry
* Removed part directory
* Make use of available icons using their name instead of downloaded images. These also match better with selected themes because they belong to a theme.

#### 2020-09-15 0.7.0
* Reorganize modules and cleanup
* Add check value of entry types
* Add first reference to site

#### 2020-08-10 0.6.0
* Build a documentation site for the project.
* CHANGES file not updated anymore. Look for it [here](https://martimm.github.io/qa-manager//content-docs/About/release-notes.html)

#### 2020-02-19 0.5.0
* Add Sheet module. Categories are now in the Categories.d directory and sheets will go into Sheets.d directory.
* Moved QATypes to QAManager directory.

#### 2020-02-07 0.4.0
* Add style sheets to show faulty input. Fields now have a red or green border color to show its status.
* Check for required fields added
* Show example test in text input
* Show tooltip text
* Finish will not exit when there are errors.
* Show message dialog on Finish when there are some errors.
* Callback implemented to check on text input

#### 2020-02-06 0.3.0
* Invoice Gui buildup ok now
* data can be injected in invoice fields and data can be extracted from fields

#### 2020-02-02 0.2.0
* Refactored QAManager -> QAManager::KV, QAManager::Set and QAManager::Category.
* Bugfixes in serialization and deserialization to Json.
* Add Gui::Main and Gui::TopLevel to present sheets to user to be filled in.

#### 2020-01-29 0.1.0
* Module QAManager

#### 2020-01-28 0.0.1
* Setup project.
* Design
