use v6.d;

#-------------------------------------------------------------------------------
unit class QA::Question:auth<github:MARTIMM>;

use QA::Types;

has Str $.action is rw;         # optional key (=methodname) to perform action
has Bool $.buttons is rw;       # optional hide buttons when repeat is True
has Str $.callback is rw;       # optional key (=methodname) to check value
has Str $.cmpwith is rw;        # optional to check value against other field
has Any $.default is rw;        # optional default value
has Str $.description is rw;    # optional
has Str $.dnd is rw;            # optional make widget a drop destination
has Array $.fieldlist is rw;    # when a list is displayed in e.g. combobox
has QAFieldType $.fieldtype is rw;  # optional = QAEntry, QADialog or QACheckButton
has Int $.height is rw;         # optional height in pixels
has Bool $.hide is rw;          # optional hide question, default False
has Bool $.invisible is rw;     # when value is displayed as dotted characters
has Str $.name is required;     # key to values and name in widgets
has Hash $.options is rw;       # options for input widgets
has Int $.page-type is rw;      # optional page type mostly used for Assistant
has Bool $.repeatable is rw;    # when value is repeatable
has Bool $.required is rw;      # when value is required
has Array $.selectlist is rw;   # when a list is displayed in e.g. combobox
has Str $.title is rw;          # optional = $!name.tclc
has Str $.tooltip is rw;        # optional tooltip value for tooltip
has Str $.userwidget is rw;     # key to user widget object
has Int $.width is rw;          # optional width in pixels

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$!name, Hash :$qa-data ) {

#note "\n", $qa-data.perl;

  # if field is defined in approprate type
  if $qa-data<fieldtype> ~~ QAFieldType {
    $!fieldtype = $qa-data<fieldtype>;
  }

  # it is a string when deserialized from json or yaml
  elsif $qa-data<fieldtype> ~~ Str {
    if QAFieldType.enums{$qa-data<fieldtype>}.defined {
      $!fieldtype = QAFieldType(QAFieldType.enums{$qa-data<fieldtype>});
    }

    else {
      die "$qa-data<fieldtype> field type does not exist";
    }
  }

  # if fieldtype is not defined (or wrong), try to find a default
  # depending on type
  else {
    $!fieldtype = QAEntry;
  }


  $!action = $qa-data<action> if $qa-data<action>.defined;
  $!buttons = $qa-data<buttons> if $qa-data<buttons>.defined;
  $!callback = $qa-data<callback> if $qa-data<callback>.defined;
  $!cmpwith = $qa-data<cmpwith> if $qa-data<cmpwith>.defined;
  $!default = $qa-data<default> if $qa-data<default>.defined;
  $!description = $qa-data<description> if $qa-data<description>.defined;
  $!dnd = $qa-data<dnd> if $qa-data<dnd>.defined;
  $!fieldlist = $qa-data<fieldlist> if $qa-data<fieldlist>.defined;
  $!height = $qa-data<height> if $qa-data<height>.defined;
  $!hide = $qa-data<hide> if $qa-data<hide>.defined;
  $!invisible = $qa-data<invisible> if $qa-data<invisible>.defined;
  $!options = $qa-data<options> if $qa-data<options>.defined;
  $!page-type = $qa-data<page-type> if $qa-data<page-type>.defined;
  $!repeatable = $qa-data<repeatable> if $qa-data<repeatable>.defined;
  $!required = $qa-data<required> if $qa-data<required>.defined;
  $!selectlist = $qa-data<selectlist> if $qa-data<selectlist>.defined;
  $!title = $qa-data<title> // $!name.tclc;
  $!tooltip = $qa-data<tooltip> if $qa-data<tooltip>.defined;
  $!userwidget = $qa-data<userwidget> if $qa-data<userwidget>.defined;
  $!width = $qa-data<width> if $qa-data<width>.defined;

#  $!category = $qa-data<category> if $qa-data<category>.defined;
#  $!set = $qa-data<set> if $qa-data<set>.defined;
}

#-------------------------------------------------------------------------------
method qa-data ( --> Hash ) {
  my Hash $qa-data = %( :$!name, :$!fieldtype);

  $qa-data<action> = $!action if $!action.defined;
  $qa-data<buttons> = $!buttons if $!buttons.defined;
  $qa-data<callback> = $!callback if $!callback.defined;
  $qa-data<default> = $!default if $!default.defined;
  $qa-data<description> = $!description if $!description.defined;
  $qa-data<dnd> = $!dnd if $!dnd.defined;
  $qa-data<fieldlist> = $!fieldlist if $!fieldlist.defined;
  $qa-data<height> = $!height if $!height.defined;
  $qa-data<hide> = $!hide if $!hide.defined;
  $qa-data<invisible> = $!invisible if $!invisible.defined;
  $qa-data<options> = $!options if $!options.defined;
  $qa-data<page-type> = $!page-type if $!page-type.defined;
  $qa-data<required> = $!required if $!required.defined;
  $qa-data<repeatable> = $!repeatable if $!repeatable.defined;
  $qa-data<selectlist> = $!selectlist if $!selectlist.defined;
  $qa-data<title> = $!title if $!title.defined;
  $qa-data<tooltip> = $!tooltip if $!tooltip.defined;
  $qa-data<userwidget> = $!userwidget if $!userwidget.defined;
  $qa-data<width> = $!width if $!width.defined;

#  $qa-data<set> = $!set if $!set.defined;
#  $qa-data<category> = $!category if $!category.defined;

  $qa-data
}

#-------------------------------------------------------------------------------
