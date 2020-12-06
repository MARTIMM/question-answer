---
title: Configuration
nav_menu: default-nav
sidebar_menu: config-sidebar
layout: sidebar
---

# Todo notes:

* Change questionaire after a combobox selection, check- or radio button clicks or switch changes. Solutions to implement this can be
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
