---
title: Configuration
nav_menu: default-nav
sidebar_menu: config-sidebar
layout: sidebar
---

# Structures

Structures are shown to have an idea how the files are defined. Categories and Sheets are stored on disk. The other structures are in categories, sets or sheets.


## Category

A category is used for archiving sets. It does not need a name, title or description. The name of the file, without its extension, is the name of the category. The data is stored in a JSON format.

* **sets**; An array of hashes.

```
{ "sets": [ {
      ... set ...
    }, {
      ... next set ...
    }
  ]
}
```


## Set

A set is not stored on disk on its own. A set is used to group a series of questions. A set has a name, a title and a description.

* **name**; Name is used as a key to get or set the input fields. It is also used to refer to a set from a sheet.
* **title**; Used as a label in a frame widget.
* **description**; Shown in above mentioned frame to describe the questions in this set.
* **hide**; Hide this set. A use for it to hide or view a set in an action handler.
* **questions**; An array of hashes.

```
"name": used as a key to get and save values,
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

Questions are what it is all about. In short a piece of text to pose the question and a field where the answer can be given. However, more data is needed to fully display a question like what kind of input do we need, are there limits, is there a choice from a set of possibilities etc.

* **callback**; A name of a method which can be called on a previously provided object. The handler must check for correctness of the input value for that question.
* **default**; A default value when no input is provided.
* **description**; A question. When empty, title is taken.
* **encode**; Encode the result of the input before giving the answers back to the caller. Used with e.g. password input.
* **example**; An example answer/format in light gray in an text field.
* **fieldlist**; The fieldlist is used to fill e.g. a combobox or a list input field.
* **fieldtype**; The widget type to use to provide the answer with. Current enumerated types are: `QAEntry` for text, `QATextView` for multiline text, `QAComboBox` a list of possibilities to chose from, `QARadioButton` a select of one of a set of possebilities, `QACheckButton`, one or more possebilities `QAToggleButton` boolean input, `QAScale` a slider, `QASwitch` also boolean input, `QAUserWidget` with a user definable input. Other types are `QADragAndDrop`, `QAColorChooser`, `QAFileChooser`, `QAList`, `QASpin` and `QAImage`. These are not yet implemented.
* **height**; Sometimes a height is needed for a widget.
* **hide**; Hide this question. A use for it to hide or view a set in an action handler.
* **invisible**; Make text input unreadable by showing stars (\*) e.g. password input.
* **maximum**; Upper limit of the input or widget. E.g. Scale.
* **minimum**; Lower limit of the input or widget. E.g. Scale.
* **name**; Used in Gui to set and retrieve data. This name is also set on the input widget to be able to find it.
* **repeatable**; A field can be extended with another input for the same question. E.g. email addresses or telephone numbers.
* **required**; An input is required. It is shown with a star at the front of the input.
* **selectlist**; The selectlist is used with input fields where a combobox is placed in front of the input field. E.g. a text input of a telephone number can be set for a home, work or mobile phone. The names 'home', 'work' or 'mobile' are then showed in the combobox. Other types might also have these possibilities.
* **step**; Step size for the slider.
* **title**; unused if there is a description, otherwise it is used as the question text.
* **tooltip**; Some helpful message shown on the input field.
* **userwidget**; Key to the previously stored user widget as input widget.
* **width**; sometimes a width is needed for a widget.


#### Notes
* Default fieldtype is QAEntry
* Boolean values like required, encode and hide are `False` if not mentioned.
* Default values are '' or 0 when absent. Min and Max are -Inf and Inf when absent.
* Encoding is done using sha256.
* select lists in a question descriptions are always arrays.
* Defaults are always single valued.
* Callback names are method names in a user class. To provide these information there are several routines defined for this in **QAManager::QATypes**.

### Answer value format to questions

Result returned from the QA dialog is a **Hash**. The keys to a questions answer is following a path through the sheet name, set name and questions name like shown below

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

The structure of a value provided by the caller or returned by the program, can differ for each input type.

The formats used are shown below for each input type with the variables which control this output format.

|Field Type        |Repeatable|Selectlist|Returned|
|------------------|----------|----------|--------|
|**QACheckButton** |ignored|ignored|`[ $value, … ]`
|**QAColorChooser**|ignored|ignored|`$value`
|**QAComboBox**    |ignored|ignored|`$value`
|**QAEntry**       |False  |ignored|`$value`
|                  |True   |∅|`[ $value, … ]`
|                  |True   |`[ $item, … ]`|`[ :$category($value), … ]`
|**QAFileChooser** |False  |ignored|`$value`
|**QAFileChooser** |True   |∅|`[ $value, … ]`
|**QAFileChooser** |True   |`[ $item, … ]`|`[ :$category($value), … ]`
|**QAImage**       |False  |ignored|`$value`
|**QAImage**       |True   |∅|`[ $value, … ]`
|**QAImage**       |True   |`[ $item, … ]`|`[ :$category($value), … ]`
|**QAList**        |ignored|ignored|`[ $value, … ]`
|**QARadioButton** |ignored|ignored|`$value`
|**QAScale**       |ignored|ignored|`$value`
|**QASwitch**      |ignored|ignored|`$value`
|**QATextView**    |ignored|ignored|`$value`
|**QAToggleButton**|ignored|ignored|`$value`
|**QASpinButton**  |ignored|ignored|`$value`
|**QAUserWidget**  |user definable|user definable|user definable

<!--
|**QADragAndDrop** |ignored|ignored|`$value`
-->

<br/>
#### A table where field specs are shown for each field type

| Symbol | Explanation
|--------|-------------------------------------------|
|!       | Must be provided with used type
|o       | Optional
|-       | Cannot be used and is ignored
|        | Unknown yet

<br/>

| Field Type              | Used letter in table header| Implemented |
|-------------------------|----------------------------|-------------|
|**QACheckButton**        | Cb                         |             |
|**QAColorChooser**       | Cc                         |             |
|**QAComboBox**           | Co                         | 🗸           |
|**QAEntry**              | En                         | 🗸           |
|**QAFileChooser**        | Fc                         | 🗸           |
|**QAImage**              | Im                         | 🗸           |
|**QAList**               | Li                         |             |
|**QARadioButton**        | Rb                         | 🗸           |
|**QAScale**              | Sc                         |             |
|**QASpinButton**         | Sp                         |             |
|**QASwitch**             | Sw                         | 🗸           |
|**QATextView**           | Tv                         | 🗸           |
|**QAToggleButton**       | Tb                         |             |
|**QAUserWidget**         | Uw                         | 🗸           |

|             |En|Cb|Co|Im|Li|Rb|Sc|Sw|Tv|Tb|Cc|Fc|Sp|Uw|
|-------------|--|--|--|--|--|--|--|--|--|--|--|--|--|--|
|callback     |o |- |- |  |  |- |  |  |o |  |  |  |  |  |
|climbrate    |- |- |- |- |- |- |o |- |- |- |- |- |o |  |
|default      |o |o |o |o |o |o |o |o |o |o |o |o |o |  |
|description  |o |o |o |o |o |o |o |o |o |o |o |o |o |  |
|digits       |- |- |- |- |- |- |o |- |- |- |- |- |o |  |
|encode       |o |- |- |- |- |- |- |- |- |- |- |- |- |  |
|example      |o |- |- |- |- |- |- |- |- |- |- |- |- |  |
|fieldlist    |- |! |! |- |! |! |  |  |  |  |  |  |  |  |
|fieldtype    |o |! |! |! |! |! |! |! |! |! |! |! |! |! |
|height       |- |- |- |o |  |- |  |  |o |  |  |  |  |  |
|hide         |o |o |o |o |o |o |o |o |o |o |o |o |o |  |
|invisible    |o |- |- |- |- |- |- |- |- |- |- |- |- |  |
|maximum      |o |- |- |- |- |- |o |- |o |- |- |- |o |  |
|minimum      |o |- |- |- |- |- |o |- |o |- |- |- |o |  |
|name         |! |! |! |! |! |! |! |! |! |! |! |! |! |! |
|page-incr    |- |- |- |- |- |- |o |- |- |- |- |- |o |  |
|page-size    |- |- |- |- |- |- |o |- |- |- |- |- |o |  |
|repeatable   |o |- |- |o |  |- |  |  |  |  |o |o |  |  |
|required     |o |o |o |o |o |o |o |o |o |o |o |o |o |  |
|selectlist   |o |- |- |o |- |- |- |- |- |- |o |o |- |  |
|step-incr    |- |- |- |- |- |- |o |- |- |- |- |- |o |  |
|title        |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|tooltip      |o |o |o |o |o |o |o |o |o |o |o |o |o |o |
|userwidget   |- |- |- |- |- |- |- |- |- |- |- |- |- |! |
|width        |- |- |- |o |  |- |  |  |  |  |  |  |  |  |

## Sheet

The sheet is used to present questions to the user. In a sheet there are pages which hold sets of questions. When shown there is only one page visible and using tabs or buttons you can show another.

* **display**; The type of dialog. One can choose from `QADialog`, `QANoteBook`, `QAStack` or `QAAssistant`.
* **width**; The minimum width of the dialog.
* **height**; The minimum height of the dialog.
* **button-map**; A map of button names. For instance on a login one would not like to have a 'Finish' label on a button but 'Login'. So an entry could be `"finish": "login"`. First letter uppercase is done automatically.
* **pages**; An array of hashes.

```
{ "display": dialog type
  "width": ... ,
  "height": ... ,
  "button-map": {
    default label: new label ,
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

* **name**; Used in user interface to set and retrieve data.
* **title**; A text used in a frame label at the top of the page
* **description**; A text shown in this frame
* **sets**; An array of hashes.

The sets in the page are referred to by using names of the category and set.
* **category**; A category name used as a reference to the categories in the archive directory
* **set**; A Set name in this category.

```
"name": used as a key to get and save values,
"title": ... ,
"description": ... ,
"sets": [ {
    "category": ...,
    "set": ...
  }, {
    ... next set ...
  }
]
```
