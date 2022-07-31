---
title: Configuration
nav_menu: default-nav
sidebar_menu: config-sidebar
layout: sidebar
---

# Todo notes:

* Change questionaire some kind of input widget change
  * [ ] Add questions. Adding questions can be done by inserting templates of a question, a set of questions or a sheet of sets. It would be necessary to modify the name field to keep the question, set or sheet unique. The insertion of the new objects must be done before of after an existing object by using the name field of the existing object.
  * [ ] Remove questions. Removing questions, sets or pages using the name field.
  * [ ] Enable/disable questions
  * [ ] Hide/show sheets, sets or questions
  * Modify data in input of a different question.
    * [x] Data must come from a user supplied routine which is called after checking the data.
    * A widget must be pointed at to set the data. This info can come from a user routine or as an option field in a question structure.
      * [ ] Append data
      * [ ] Replace data
  * [ ] Modify accompanying combobox lists of questions
  * [ ] Optionally(?) save modified questionaire configuration


# Implementation

When interface is created where are the hooks to work with?
* User app creates **QA::Gui::Sheet**s using `QA::Gui::Sheet*.new()`;
* Each Sheet object creates **QA::Gui::Page**s `QA::Gui::SheetTools!create-page()` in **QA::Gui::SheetTools** `$!pages`.
* The pages are filled with sets using `QA::Gui::Set.new()`
* The sets are stored in **QA::Gui::Page** `$!sets`.
* Questions are created in `QA::Gui::Sets.new()` and stored in **QA::Gui::Sets** `$!questions`.

The user data filled in into the questions comes from a file or created empty when field is empty. When everything is running, only event handlers in the questions are able to check and store this data. So, from here (`QA::Gui::QA*` / `QA::Gui::Value` widget) we must find a hook (question,set or page name) to operate on.
* Provide the sheet Hash to the created sets.
* Provide the sheet, set and question Hashes to the created questions.
* The searched item must have a code to select a sheet, set or question and the name of it. For example 'Qst:radio-station' or 'Sht:page1'. Lets call it a hook-spec. The format can then be `<hook-spec>.<operation>;…`
* Now we can use the `action-cb` field to specify the method name. This callback can then get the data and return an array to ask for further actions.


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
