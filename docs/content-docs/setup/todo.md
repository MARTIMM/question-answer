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
  * Modify data in input of a different question.
    * [ ] Data must come from a user supplied routine which is called after checking the data.
    * A widget must be pointed at to set the data. This info can come from a user routine or as an option field in a question structure.
      * [ ] Append data
      * [ ] Replace data
  * [ ] Modify accompanying combobox lists of questions
  * [ ] Optionally(?) save modified questionaire configuration



# Implementation

When interface is created
* User app creates some Sheets using `QA::Gui::Sheet*.new()`;
* Each Sheet object creates **QA::Gui::Page**s `QA::Gui::SheetTools!create-page()` in **QA::Gui::SheetTools** `$!pages`.
* The pages are filled with sets using `QA::Gui::Set.new()`
* The sets are stored in **QA::Gui::Page** `$!sets`.
* Questions are created in `QA::Gui::Sets.new()` and stored in **QA::Gui::Sets** `$!questions`.
*


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
