use v6.d;
use Test;

use QA::Sheet;
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

# create some sets
make-sets();

my QA::Sheet $sheet .= new(:sheet-name<login>);

#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $sheet, QA::Sheet, '.new(:sheet-name)';
}

#-------------------------------------------------------------------------------
subtest 'Save and load sheet', {

  ok $sheet.new-page(:name<tstsheet2>), '.new-page() tstsheet2';

  ok $sheet.new-page(:name<tstsheet3>), '.new-page() tstsheet3';
  ok $sheet.add-set(:set-name<credentials>), '.add-set()';
  ok $sheet.add-set(:set-name<profile>), '.add-set()';
  ok $sheet.remove-set(:set-name<credentials>), '.remove-set()';

  ok $sheet.new-page(
    :name<tstsheet1>,
    :title("Test Sheet 1"),
    :description("Description jzh glfksd slfdjg sdfgl jsfdg lsdfg jhsdlfgj sdfg lsdkj sdgljshdfg ls dfj sdf glsjfdg sdflg ksdlfgj sdfg sdflkhsdf gsdfkggh"
    )
  ), '.new-page() tstsheet1';

  ok $sheet.add-set(:set-name<credentials>), '.add-set()';
  nok $sheet.remove-set(:set-name<creds>), 'creds set not added';
  nok $sheet.remove-set(:set-name<profile>), 'profile set not removed';
  ok $sheet.remove-set(:set-name<credentials>), '.remove-set()';

  ok $sheet.add-set(:set-name<credentials>), '.add-set()';
  ok $sheet.add-set(:set-name<profile>), '.add-set()';

  $sheet.delete-page(:name<tstsheet2>);
  $sheet.save;
  ok "@dirs[SHEET]/login.yaml".IO ~~ :e, '.save() login';

  $sheet.save-as('login2');
  ok "@dirs[SHEET]/login2.yaml".IO ~~ :e, '.save-as() login2';


  my $c := $sheet.clone;
  my @sheets = <tstsheet3 tstsheet1>;
  for $c -> Hash $page {
    is $page<name>, @sheets.shift, "page iterator $page<name>";
  }

  $sheet .= new(:sheet-name<login2>);
  ok $sheet.remove, 'login2 deleted';

  # cannot remove unloaded sheets
  $sheet .= new(:sheet-name<login>);
  ok $sheet.remove, 'login removed';
  nok $sheet.remove, 'login already removed';
}

#-------------------------------------------------------------------------------
my QA::Set $set .= new(:name<credentials>);
$set.remove;
$set .= new(:name<profile>);
$set.remove;

done-testing;


#-------------------------------------------------------------------------------
# create a few sets
sub make-sets ( ) {

  # 1 set
  my QA::Set $set .= new(:name<credentials>);
  $set.description = 'Name and password for account';

  # 1st question and add to set
  my QA::Question $question .= new(:name<username>);
  $question.description = 'Username of account';
  $question.required = True;
  $set.add-question($question);

  # 2nd question and add to set
  $question .= new(:name<password>);
  $question.description = 'Password for username';
  $question.required = True;
  $question.invisible = True;
  $set.add-question($question);

  # save the set
  $set.save;

  # 2 set
  $set .= new(:name<profile>);
  $set.description = 'Extra info for account';

  # 1st question and add to set
  $question .= new(:name<work-address>);
  $question.description = 'Work Address';
  $question.required = True;
  $set.add-question($question);

  # save 2nd set
  $set.save;
}
