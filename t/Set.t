use v6.d;
use Test;

#use QAManager;
use QA::Set;
use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
# set a few values before initializing
enum DE <SET SHEET UDATA>;
my @dirs = <t/Data/Sets t/Data/Sheets t/Data/Userdata>;
for @dirs -> $d {
  mkdir $d, 0o700 unless $d.IO.e;
}

given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .cfgloc-userdata(@dirs[UDATA]);
  .cfgloc-sheet(@dirs[SHEET]);
  .cfgloc-set(@dirs[SET]);
}

my QA::Set $creds .= new(:name<credentials>);

#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $creds, QA::Set, '.new(:name)';
}

#-------------------------------------------------------------------------------
subtest 'Create questions', {
  is $creds.title, 'Credentials', '.title()';
  $creds.description = 'Name and password for account';

  my QA::Question $un .= new(:name<username>);
  $un.description = 'Username of account';
  $un.required = True;

  my QA::Question $pw .= new(:name<password>);
  $pw.description = 'Password for username';
  $pw.required = True;
  $pw.invisible = True;

  ok $creds.add-question($un), '.add-question()';
  nok $creds.add-question($un), 'allready added';
  ok $creds.add-question($pw), '.add-question()';
  ok $creds.replace-question($pw), '.replace-question()';

#  note $creds.set;
}

#-------------------------------------------------------------------------------
subtest 'Save and load set', {
  $creds.save;
  ok "@dirs[SET]/credentials.yaml".IO ~~ :e, '.save()';

  my QA::Set $new-creds .= new(:name<credentials>);
  my QA::Question $question = $new-creds.get-question('username');
  is $question.description, 'Username of account', 'from set file';

  ok $new-creds.remove, '.remove()';
  nok $new-creds.remove, 'already removed';
  ok "@dirs[SET]/credentials.yaml".IO ~~ :!e, 'file removed';
}

#-------------------------------------------------------------------------------
done-testing
