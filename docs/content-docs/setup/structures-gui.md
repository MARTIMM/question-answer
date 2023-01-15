---
title: Configuration
nav_menu: default-nav
sidebar_menu: sidebar-config
layout: sidebar
---
# Sheet Types

## Simple Sheet

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }

  .gray {
    BackgroundColor #ffffff
    FontColor #aaaaaa
  }
}
</style>

* Dialog
** Box
*** Grid
**** ScrolledWindow
***** page layout <<rose>>
**** Statusbar
*** Box
**** ButtonBox
***** Button (cancel)
***** Button (save-quit)
***** Button (save-continue)
@endmindmap
```

## Notebook

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }

  .gray {
    BackgroundColor #ffffff
    FontColor #aaaaaa
  }
}
</style>

* Dialog
** Box
*** Grid
**** Notebook
***** ScrolledWindow
****** page layout <<rose>>
***** Label (tab)
***** … repeated  …
**** Statusbar
*** Box
**** ButtonBox
***** Button (cancel)
***** Button (save-quit)
***** Button (save-continue)
@endmindmap
```

## Stack

## Assistant


# Layout of a Sheet

## Page Layout

Each set is a row in the grid.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* Viewport
** Grid
*** set layout <<rose>>
'** set layout <<rose>>
*** … <<rose>>

@endmindmap
```


## Set Layout

A set is a framed grid of which the first row shows a descriptive text of the set. The second row is a separator. Then a series of questions follows in the remaining rows.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

** Frame
** Grid
*** Label (set description text)
*** Separator
*** question <<rose>>
'*** question <<rose>>
*** … <<rose>>
** Label (frame)


@endmindmap
```


## Question
A question is a row in a grid. The input field is always framed but the frame is only visible when `$!question.repeatable` is turned on to group the input fields. In the frame there is a grid to contain the several input fields.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* question <<rose>>
** Label (question text)
** Label (required star)
** Frame (visible on repeat)
*** Grid
**** input field <<rose>>
'**** input field <<rose>>
**** … <<rose>>
@endmindmap
```


## Input Field
Each grid row contains a selection list if `$!question.selectlist` is valid, the input widget and a tool button when `$!question.repeatable` is on. The tool button shows a '+' and another button for a '-' on the last row to add a new row or to remove that row. Otherwise it shows a '-' to delete the row.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* input field <<rose>>
** ComboBoxText
** input widget <<rose>>
** ToolButton (name 'tb:#')
@endmindmap
```



# Input widgets

Most input widgets are simple like `QAEntry`, `QASwitch` and `QAComboBoxText`. Only the more elaborate widgets are shown here.

## QARadioButton

The widget combines a series of radio buttons in a grid. The radio buttons are member of the same group

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* input widget <<rose>>
** Grid
*** RadioButton
'*** RadioButton
*** …
@endmindmap
```

## QACheckButton

The widget combines a series of check buttons in a grid.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* input widget <<rose>>
** Grid
*** CheckButton
'*** CheckButton
*** …
@endmindmap
```

## QAImage

The widget a grid with a file chooser button and an image. Images from file managers can be dragged on the file chooser button. The image displays the result. When `$!question.dnd` is valid, the chooser button will not be visible. Multiple files can then be dragged upon an image or the empty image. The first images replaces the image where it is dropped, the rest is added to the list.

```plantuml
@startmindmap
scale 0.9
<style>
mindmapDiagram {
  node {
    BackgroundColor lightGreen
  }

  .rose {
    BackgroundColor #ffdddd
  }
}
</style>

* input widget <<rose>>
** Grid
*** FileChooserButton (name '')
*** Image
@endmindmap
```
