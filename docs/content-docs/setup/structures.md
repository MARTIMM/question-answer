---
title: Configuration
nav_menu: default-nav
sidebar_menu: config-sidebar
layout: sidebar
---

# Structures

Structures are shown to have an idea how the files are defined. Categories and Sheets are stored on disk. The other structures are in categories, sets or sheets.

All name fields in a configuration file must be unique so that it can also be used as a hook to operate on. Current and future usages are;
* Search and modify sheets, sets and questions.
* A name is used as an id for error messages.

## Set

A set is not stored on disk on its own. A set is used to group a series of questions. A set has a name, a title and a description.

* **set-name**; Name is used as a key to get or set the input fields. It is also used to refer to a set from a sheet.
* **title**; Used as a label in a frame widget.
* **description**; Shown in above mentioned frame to describe the questions in this set.
* **hide**; Hide this set. A use for it to hide or view a set in an action handler.
* **questions**; An array of hashes. While the name of a question mus be unique, we cannot have a Hash instead of an Array. This because the order of entries in a hash is unpredictable.

```
"set-name": used as a key to get and save values,
"title": ... ,
"description":  ... ,
"hide": ... ,
"questions": [ {
      ... question ...
  }, {
    ... next question ...
  }
]
```


## Questions

Questions are what it is all about. In short, a piece of text to pose the question and a field where the answer can be given. However, more data is needed to fully display a question like what kind of input do we need, are there limits, is there a choice from a set of possibilities etc.

* **action**; A name of a method which can be called on a previously provided object. The method is called when the answer on the question in accepted and saved in the users data.
* **buttons**; Show buttons when repeatable is turned on. This is on by default. You might turn it off if you want to use keys and/or drag and drop.
* **check-cb**; A name of a method which can be called on a previously provided object. The handler must check for correctness of the input value for that question and return an error message if test fails.
* **default**; A default value when no input is provided.
* **description**; A question. When empty, title is taken.
* **fieldlist**; The fieldlist is used to fill e.g. a combobox or a list input field.
* **fieldtype**; The widget type to use to provide the answer with. Current enumerated types are: `QAEntry` for text, `QATextView` for multiline text, `QAComboBox` a list of possibilities to chose from, `QARadioButton` a select of one of a set of posibilities, `QACheckButton`, one or more possebilities `QAToggleButton` boolean input, `QAScale` a slider, `QASwitch` also boolean input, `QAUserWidget` with a user definable input. Other types are `QAColorChooser`, `QAFileChooser`, `QAList`, `QASpin` and `QAImage`. Some of these are not yet implemented.
* **height**; Sometimes a height is needed for a widget.
* **hide**; Hide this question. A use for it to hide or view a set in an action handler.
* **name**; Used in Gui to set and retrieve data. This name is also set on the input widget to be able to find it.
* **options**; A hash of options for the input objects
* **repeatable**; A field can be extended with another input for the same question. E.g. email addresses or telephone numbers.
* **required**; An input is required. It is shown with a star at the front of the input.
* **selectlist**; The selectlist is used with input fields where a combobox is placed in front of the input field. E.g. a text input of a telephone number can be set for a home, work or mobile phone. The names 'home', 'work' or 'mobile' are then showed in the combobox. Other types might also have these possibilities.
* **title**; unused if there is a description, otherwise it is used as the question text.
* **tooltip**; Some helpful message shown on the input field.
* **userwidget**; Key to the previously stored user widget as input widget.
* **width**; sometimes a width is needed for a widget.

### List of options for input widgets

* **QACheckButton**
* **QAColorChooser**
* **QAComboBox**
* **QAEntry**
  * **example**; An example answer/format in light gray in an text field.
  * **invisible**; Make text input unreadable by showing stars (\*) e.g. password input.
  * **maximum**; Maximum number of characters.
  * **minimum**; Minimum number of characters.
* **QAFileChooser**
  * **action**; The way the chooser selects a file or directory. This can be one of
    `open`; Indicates open mode. The file chooser will only let the user pick an existing file.
    `save`; Indicates save mode. The file chooser will let the user pick an existing file, or type in a new filename.
    `select`; Indicates an Open mode for selecting folders. The file chooser will let the user pick an existing folder.
    `create`; Indicates a mode for creating a new folder. The file chooser will let the user name an existing or new folder.
* **QAImage**
  * **dnd**; Make this widget a drag destinatio. Its value is a list of target names such as `text/plain, text/x-perl`. You can also makeup targets as long as you have some source application supporting the targets.
* **QARadioButton**
* **QASwitch**
* **QATextView**
  * **maximum**; Maximum number of words.
  * **minimum**; Minimum number of words.
* **QAToggleButton**
* **QASpinButton**
  * **climbrate**; specifies by how much the rate of change in the value will accelerate if you continue to hold down an up/down button or arrow key. default set to 1.5e0.
  * **digits**; The number of decimal places to display.
  * **maximum**; Upper limit of the input. Default is 1e2.
  * **minimum**; Lower limit of the input. Default is 0e0.
  * **page-incr**; Sets the page increment. Default is 2e0.
  * **page-size**; Sets the page size. Default is 1e1.
  * **step-incr**; Sets the step increment. Default is 1e0.
* **QAUserWidget**

### Notes
* Default fieldtype is QAEntry
* Boolean values like required and hide is `False` if not mentioned.
* Other values are '' or 0 by default when absent. Minimum and maximum are -Inf and Inf when absent.
* Select lists in question descriptions are always arrays.
* Defaults are always single valued.
* Callback and action names are keys referring to method names in a user class. To provide this information there are several routines defined for this in **QA::QATypes**.


### Answer value format to questions

The result returned from the QA dialog is a **Hash**. The keys to a questions answer is following a path through the sheet name, set name and questions name like shown below;

```
page-name1 => {
  set-name1 => {
    question-name1 => value-spec,
    question-name2 => ...
    ...
  },
  set-name2 => {
    ...
  }
},

page-name2 => {
  ...
}
```


The structure of a value-spec provided by the caller or returned by the program, can differ for each input type.

The formats used are shown below for each input type with the variables which control this output format.

|Field Type        |Repeatable|Selectlist         |Returned       |
|------------------|----------|-------------------|---------------|
|**QACheckButton** |ignored   |ignored            |`[ $value, … ]`
|**QAColorChooser**|ignored   |ignored            |`$value`
|**QAComboBox**    |ignored   |ignored            |`$value`
|**QAEntry**       |False     |ignored            |`$value`
|                  |True      |∅                  |`[ $value, … ]`
|                  |True      |`[ $category, … ]` |`[ :$category($value), … ]`
|**QAFileChooser** |False     |ignored            |`$value`
|                  |True      |∅                  |`[ $value, … ]`
|                  |True      |`[ $category, … ]` |`[ :$category($value), … ]`
|**QAImage**       |False     |ignored            |`$value`
|                  |True      |∅                  |`[ $value, … ]`
|                  |True      |`[ $category, … ]` |`[ :$category($value), … ]`
|**QAList**        |ignored   |ignored            |`[ $value, … ]`
|**QARadioButton** |ignored   |ignored            |`$value`
|**QAScale**       |ignored   |ignored            |`$value`
|**QASwitch**      |ignored   |ignored            |`$value`
|**QATextView**    |ignored   |ignored            |`$value`
|**QAToggleButton**|ignored   |ignored            |`$value`
|**QASpinButton**  |ignored   |ignored            |`$value`
|**QAUserWidget**  |user definable|user definable |user definable

<br/>

### A table where field specs are shown for each field type

| Symbol | Explanation
|--------|-------------------------------------------|
|!       | Must be provided with used type
|o       | Optional
|-       | Cannot be used and is ignored
|        | Unknown yet

<br/>

| Field Type              | Used letter in table header| Implemented |
|-------------------------|----------------------------|-------------|
|**QACheckButton**        | Cb                         | ✓           |
|**QAColorChooser**       | Cc                         |             |
|**QAComboBox**           | Co                         | ✓           |
|**QAEntry**              | En                         | ✓           |
|**QAFileChooser**        | Fc                         | ✓           |
|**QAImage**              | Im                         | ✓           |
|**QAList**               | Li                         |             |
|**QARadioButton**        | Rb                         | ✓           |
|**QAScale**              | Sc                         |             |
|**QASpinButton**         | Sp                         | ✓           |
|**QASwitch**             | Sw                         | ✓           |
|**QATextView**           | Tv                         | ✓           |
|**QAToggleButton**       | Tb                         |             |
|**QAUserWidget**         | Uw                         | ✓           |

|             |En|Cb|Co|Im|Li|Rb|Sc|Sw|Tv|Tb|Cc|Fc|Sp|Uw|
|-------------|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|action       |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|buttons      |o |- |- |o |- |- |- |- |  |- |o |o |  |  | <!-- optional? -->
|check-cb     |o |- |- |  |  |- |  |  |o |  |  |  |  |  |
|default      |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|description  |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|fieldlist    |- |! |! |- |! |! |  |  |  |  |  |  |  |o | <!-- optional? -->
|fieldtype    |o |! |! |! |! |! |! |! |! |! |! |! |! |! |
|height       |- |- |- |o |  |- |  |  |o |  |  |  |  |o | <!-- optional? -->
|hide         |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|name         |! |! |! |! |! |! |! |! |! |! |! |! |! |! |
|options      |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|repeatable   |o |- |- |o |  |- |  |  |  |  |o |o |  |  | <!-- optional? -->
|required     |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|selectlist   |o |- |- |o |- |- |- |- |- |- |o |o |- |  | <!-- optional? -->
|title        |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|tooltip      |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|userwidget   |- |- |- |- |- |- |- |- |- |- |- |- |- |! |
|width        |- |- |- |o |  |- |  |  |  |  |  |  |  |  | <!-- optional? -->

## Sheet

The sheet is used to present questions to the user. In a sheet there are pages which hold sets of questions. When shown there is only one page visible and using tabs or buttons you can show another.

* **width**; The minimum width of the dialog.
* **height**; The minimum height of the dialog.
* **button-map**; A map of button names to a structure. There are two default buttons `save-quit` and `cancel` which do not need extra info and will be displayed by default. For changes and additions one need a structure. For instance on a login one would not like to have a 'save-quit' label on a button but rename it to `Login`. The first letter of every word is uppercased and dashes are replaced with spaces. If a button is not desired, i.e. the default visible ones, a button is hidden when a name is set to an empty string. Otherwise, without a structure, the button is not shown.

  The supported buttons are;
  * `save-quit`; Save and close. Checks are done to see if it is safe to save. Its options may be;
    * `name`; Different text on the button or empty string to hide the button.

  * `save-continue`: Save but do not close. Checks are done. This works like an 'Apply'.
    * `name`; Different text on the button.

  * `cancel`; Close without saving.
    * `name`; Different text on the button or empty string to hide the button.

  * `help-info`; Show help dialog. Text is from `help-message`,
    * `name`; Different text on the button.
    * `message`; When help button is shown, this text is displayed. When absent, the help button is NOT shown.

  * `user`; A user definable button.
    * `name`; Different text on the button.
    * `action`; A name of a method which can be called on a previously provided object. The method is called when the answer on the question in accepted and saved in the users data. This is like the action from the question explained above.

* **pages**; An array of hashes.

```
{ "width": ... ,
  "height": ... ,
  "button-map": {
    "default label text": {
      "name": "changed label text",
      "text": "optional text",
      "action": "optional action"
    }
    ...
  },
  "pages": [ {
      ... page ...
    }, {
      ... next page ...
    },
  ]
}
```


## Page

The questions are grouped in sets as explained above. Sets are referred to from a page to prevent duplication of structures. The problem which may arise is that sets in categories can be replaced or removed. The sheet display software will than issue a warning and skips the display of that particularly set.

* **page-name**; Used in user interface to set and retrieve data.
* **title**; A text used in a frame label at the top of the page
* **description**; A text shown in this frame
* **page-type**; Page types are like `QAContent`, `QAPageIntro`, `QAConfirm`, `QASummary`, `QAProgress` or `QACustom`. The `QAContent` is the default. A few are only useful for `QAAssistant` and almost none for `QADialog`.
* **sets**; An array of set hashes.

```
"page-name": ... ,
"title": ... ,
"description": ... ,
"page-type": ... ,
"sets": [ {
    ... set ...
  }, {
    ... next set ...
  }
]
```
