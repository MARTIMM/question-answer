use v6.d;

use QA::Questionnare;
use QA::Set;
use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
# set a few values before initializing
enum DE <SET SHEET UDATA>;
my @dirs = <xbin/Movie/Sets xbin/Movie/Sheets xbin/Movie/MovieData>;
for @dirs -> $d {
  mkdir $d, 0o700 unless $d.IO.e;
}

given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata(@dirs[UDATA]);
  .cfgloc-sheet(@dirs[SHEET]);
  .cfgloc-set(@dirs[SET]);
}

# create some sets
make-sets();


with my QA::Questionnare $sheet .= new(:sheet-name<movie>) {
  .remove;
  .width = 400;
  .height = 500;
  .button-map = %( :cancel('I want to quit'), :save-quit('Ready when you are!'));
  .add-page(
    'Movie Info', :title('Movie info'),
    :description('Films and their actors')
  );
  note 'replace set: ', .add-set( 'Movie Info', 'movie');
  note 'replace set: ', .add-set( 'Movie Info', 'actor');
  .save;
}

#-------------------------------------------------------------------------------
# create a few sets
sub make-sets ( ) {

  # Set to specify a movie
  my QA::Set $set .= new(:set-name<movie>);
  note 'set removed: ', $set.remove;
  $set.description = 'Movie information';

  my QA::Question $question .= new(:name<movie-select>);
  $question.description = 'Select a movie';
  $question.fieldtype = QAFileChooser;
  $question.required = True;
  $set.add-question( $question, :replace);

  $set.save;


  # Set to specify an actor
  $set .= new(:set-name<actor>);
  note 'set removed: ', $set.remove;
  $set.description = 'Actor information';
#TODO $set.repeatable

  $question .= new(:name<actorname>);
  $question.description = 'Name of actor';
  $question.fieldtype = QAEntry;
  $question.required = True;
  $set.add-question( $question, :replace);

  $question .= new(:name<gender>);
  $question.description = 'Gender of actor';
  $question.fieldtype = QARadioButton;
  $question.fieldlist = [<male female>];
  $set.add-question( $question, :replace);

  $question .= new(:name<photo>);
  $question.description = 'A photo of actor';
  $question.fieldtype = QAImage;
  $set.add-question( $question, :replace);

  $set.save;
}
