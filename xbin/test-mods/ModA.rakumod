use v6;

unit class ModA;

has QA::Gui::PageStackWindow $.qst-window;

#-------------------------------------------------------------------------------
# TODO: a class with these methods should be loaded at runtime when
# necessary
# check methods
method check-exclam ( Str $input, :$char --> Any ) {
  "No $char allowed in string" if ?($input ~~ m/$char/)
}

#-------------------------------------------------------------------------------
# action methods
method fieldtype-action1 ( Str $input --> Array ) {
  note "Selected 1: $input";

  # return an array of follow up actions. show-select2 is mapped to
  # method fieldtype-action2
  [%( :type(QAOtherUserAction), :action-key<fieldtype-action2>, :opt1<opt1>),]
}

#-------------------------------------------------------------------------------
method fieldtype-action2 ( Str $input, :$opt1 --> Array ) {
  note "Selected 2: $input, option: $opt1";

  # no further actions
  Array
}

#`{{
method extend-selectlist ( Str $input --> Array ) {
  note "Extend select list: $input";

  # no further actions
  Array
}
}}
