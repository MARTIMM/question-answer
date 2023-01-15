---
title: Configuration
nav_menu: default-nav
sidebar_menu: sidebar-config
layout: sidebar
---

# Todo notes:

## Change questionaire

Changing a questionaire will be some action like a change of an input widget value, set or page change. See for possible changes below in the list of `$type`. Actions not defined by that variable are e.g. modifications to the  accompanying combobox lists aside the question.

* [ ] When new items are added, it would be necessary to modify the name fields in the used template to keep the question, set or page unique. The new objects must be inserted after an existing object by using the name field of that existing object and add some number to it.
* [ ] When there are changes to questions, sets or pages, it must be stored aside the original questionaire. This could be done using some sort of version tag added to the filename. It should also be simple without many versions so `<original-name>:latest.yaml` would be enough. New items are added, hidden or not. Reverting to the original by using a commandline option like `--orig` would also overwrite the latest when changes are made to the questionaire.
* [x] Data needed to do the necessary changes, must come from a user supplied method. This method is called after checking the data. The method name is found in the `action-cb` question field. It holds a key to the name of the method stored using `QA::Gui::Types.set-action-handler()`. The field is read by `QA::Gui::Value.check-users-action()` and run if valid.

  This user method can optionally return an Array of actions to perform. The format is;
  ```
  [ %( ActionReturnType :$type, *%action-data ), … ]
  ```
* The `$type` is an enumeration describing the type of action and can be one of;
  * [ ] QAHidePage
  * [ ] QAHideSet
  * [ ] QAHideQuestion

  * [ ] QAShowPage
  * [ ] QAShowSet
  * [ ] QAShowQuestion

  * [ ] QAModifyQuestion;

  * [ ] QAEnableInputWidget
  * [ ] QADisableInputWidget

  * [ ] QAOpenDialog;
  * [x] QAOtherUserAction; `%action-data = %( :action-key, *%user-options)`

  * [ ] QAModifyFieldlist
  * [ ] QAModifySelectlist

  * [ ] QAModifyValue

  * [ ] QAEnableButton
  * [ ] QADisableButton

* [ ] A widget must be pointed at to set the data. This info can come from a user routine or as an option field in a question structure.
  * [ ] Append data
  * [ ] Replace data


<!--
  * [ ] QAAddQuestion;
  * [ ] QAAddSet;
  * [ ] QAAddPage;

  * [ ] QARemoveQuestion;
  * [ ] QARemoveSet;
  * [ ] QARemovePage;
-->

## Naming of files and extensions
* [x] Change extensions into a more descriptive one. Now `.json`, `.toml` and `.yaml`. This only describes its format. It should become `.<format>-qa<type>` where format is any of `json`, `toml` or `yaml`. Type is one of `qst`, `set` or `data`. For example `.yaml-qagst` for a questionaire. Type name `set` is  for parts of a questionaire and `data` is used for the result of the questionaire.
* [x] The locations of the files are in a sheets, sets or data directory. Now the files can be distinquished by their extensions, this separation is not needed anymore. They can now be placed together in one directory.
* [x] The data file is named after the questionaire. For single configurations, this is a good enough solution. Questionnares can also be used as a test or an interview. Those results are always stored in different files for persons or objects. Therefore there must be a way to set the name of the results file.

<!--
-->
<!--
# Implementation

When interface is created where are the hooks to work with?
* User app creates **QA::Gui::Sheet**s using `QA::Gui::Sheet*.new()`;
* Each Sheet object creates **QA::Gui::Page**s `QA::Gui::PageTools!create-page()` in **QA::Gui::PageTools** `$!pages`.
* The pages are filled with sets using `QA::Gui::Set.new()`
* The sets are stored in **QA::Gui::Page** `$!sets`.
* Questions are created in `QA::Gui::Sets.new()` and stored in **QA::Gui::Sets** `$!questions`.

The user data filled in into the questions comes from a file or created empty when field is empty. When everything is running, only event handlers in the questions are able to check and store this data. So, from here (`QA::Gui::QA*` / `QA::Gui::Value` widget) we must find a hook (question,set or page name) to operate on.
* Provide the sheet Hash to the created sets.
* Provide the sheet, set and question Hashes to the created questions.
* The searched item must have a code to select a sheet, set or question and the name of it. For example 'Qst:radio-station' or 'Sht:page1'. Lets call it a hook-spec. The format can then be `<hook-spec>.<operation>;…`
* Now we can use the `action-cb` field to specify the method name. This callback can then get the data and return an array to ask for further actions.
-->

<!--
* .....
  * Template sets and pages. This can be used when a new set or page must be inserted to repeat a set of data.
  * All sets and pages are defined with a hiding control so the visibility can be switched on or off.
  * Make use of user objects with callbacks defined. Already useful to check on data besides requiredness which is handled by the manager. The callback can define actions which in turn call the manager routines to add pages from the templates. Other actions might be to hide a page.

  Some ideas for it
  * Fill a combobox with values after selection of another combobox.
  * Remove or add pages or sets in the questionaire depending on other input. Perhaps using a template describing what is on the page or set.

* Many input widget types are already available but perhaps add a ...
  * Dialog
  * Listbox
  * Treeview
  * Pane

* Now that drag and drop is implemented in the GTK binding, we can extend the widgets to accept drags from file managers and browsers
-->
