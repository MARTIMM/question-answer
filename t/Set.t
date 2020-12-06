use v6.d;
use Test;

#use QAManager;
use QA::Set;
use QA::Question;

#-------------------------------------------------------------------------------
my QA::Set $creds .= new(:name<credentials>);
#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $creds, QA::Set, '.new(:name)';
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  is $creds.title, 'Credentials', '.title()';
  $creds.description = 'Name and password for account';

  my QA::Question $un .= new(:name<username>);
  $un.description = 'Username of account';
  $un.required = True;

  my QA::Question $pw .= new(:name<password>);
  $pw.description = 'Password for username';
  $pw.required = True;
  $pw.encode = True;
  $pw.invisible = True;

  ok $creds.add-question($un), '.add-question()';
  nok $creds.add-question($un), 'allready added';
  ok $creds.add-question($pw), '.add-question()';
  ok $creds.replace-question($pw), '.replace-question()';

#  note $creds.set;
}

#-------------------------------------------------------------------------------
done-testing
