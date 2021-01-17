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

my QA::Set $creds .= new(:set-name<credentials>);

#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $creds, QA::Set, '.new(:set-name)';
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
subtest 'Save, load and change set', {
  $creds.save;
  ok "@dirs[SET]/credentials.yaml".IO ~~ :e, '.save()';

  my QA::Set $new-creds .= new(:set-name<credentials>);
  my QA::Question $question = $new-creds.get-question('username');
  is $question.description, 'Username of account', 'from set file';

  my QA::Question $pw = $new-creds.get-question('password');
  is $pw.description, 'Password for username', '.get-question()';
  $pw.description = 'Choose proper password';
  nok $new-creds.add-question($pw), 'cannot add existing entry';
  ok $new-creds.add-question( $pw, :replace), 'use :replace';
  $new-creds.save;

  $new-creds .= new(:set-name<credentials>);
  is $pw.description, 'Choose proper password', 'check after saving';
#`{{
  note " ";
  my $c := $new-creds.clone;
  for $c -> QA::Question $q {
    for $q.qa-data.kv -> $k, $v {
      note "$k => $v";
    }
    note " ";
  }
}}
}

#-------------------------------------------------------------------------------
subtest 'Remove set', {
  my QA::Set $new-creds .= new(:set-name<credentials>);
  ok $new-creds.remove, '.remove()';
  nok $new-creds.remove, 'already removed';
  ok "@dirs[SET]/credentials.yaml".IO ~~ :!e, 'file removed';
}

#-------------------------------------------------------------------------------
done-testing
