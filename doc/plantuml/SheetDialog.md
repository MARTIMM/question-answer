```plantuml
@startuml
'scale 0.9
skinparam packageStyle rectangle
skinparam stereotypeCBackgroundColor #80ffff
set namespaceSeparator ::
hide empty members

'class QA::Gui::Frame <<(R,#80ffff)>>
'class QA::Gui::Repeat <<(R,#80ffff)>>

'class QA::Gui::StatusBar <<(R,#80ffff)>>
class QA::Gui::StatusBar <Singleton>
'class Gnome::N::TopLevelClassSupport < Catch all class >

class QA::Gui::Value <<(R,#80ffff)>> {
  +initialize()

  -set-values()
  -create-input-row()
  -set-status-hint()
  -check-on-focus-change()

  +{abstract} set-value()
  +{abstract} get-value()
'  +{abstract} check-value()
  +{abstract} create-widget()

  -Array $!values
  -QA::Question $!question
  -Hash $!user-data-set-part
  -Array $!input-widgets
}

note right of QA::Gui::Value : <b>Value</b> is responsible for creating the\nsub widgets and read and write the user\nvalues in every sub widget.

class "Some Gtk\nInput Widget" as QA::Gui::GtkIOWidget

class "Some QA\nInput Widget" as QA::Gui::QAIOWidget {
  +set-value()
  +get-value()
'  +check-value()
  +create-widget()
}

note right of QA::Gui::QAIOWidget : <b>QAEntry</b> is one of the possible types.\nIt is responsible for creating the input\nwidget of which its values are saved\nby <b>Value</b>.

class QA::Gui::Set {
  -Array $questions
  -QA::Set $!set
}

class QA::Gui::SheetDialog {
  -Array $sets
}


'QA::Gui::Set *--> QA::Set
'QA::Gui::Repeat <|.. QA::Gui::QAIOWidget

QA::Gui::Dialog <|-- QA::Gui::SheetDialog
QA::Gui::Set "*" <-* QA::Gui::SheetDialog
QA::Gui::SheetDialog <--* UserApp
QA::Gui::StatusBar <--* QA::Gui::SheetDialog

QA::Gui::Value <|.. QA::Gui::QAIOWidget
QA::Gui::Frame <|-- QA::Gui::Value
QA::Gui::GtkIOWidget "*" <--* QA::Gui::Value

QA::Gui::QAIOWidget <--* QA::Gui::Question
QA::Gui::QALabel <--* QA::Gui::Question

QA::Gui::Question "*" <--* QA::Gui::Set

@enduml
```
