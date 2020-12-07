use v6.d;
use Test;

use QA::Sheet;
use QA::Category;
use QA::Set;
use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
my QA::Types $qa-types .= instance;
my QA::Sheet $sheet .= new(:sheet-name<__login>);

# create some category data with some sets
make-category();

#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $sheet, QA::Sheet, '.new(:sheet-name)';
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {

  is $sheet.display, QANoteBook, '.display()';

  ok $sheet.new-page(:name<tstsheet2>), '.new-page()';
  $sheet.new-page(:name<tstsheet3>);

  $sheet.new-page(
    :name<tstsheet1>,
    :title("Test Sheet 1"),
    :description("Description jzh glfksd slfdjg sdfgl jsfdg lsdfg jhsdlfgj sdfg lsdkj sdgljshdfg ls dfj sdf glsjfdg sdflg ksdlfgj sdfg sdflkhsdf gsdfkggh"
    )
  );

  ok $sheet.add-set( :category<__test-accounting>, :set<credentials>),
     '.add-set()';
  nok $sheet.remove-set( :category<__test-accounting>, :set<creds>),
     'creds set not added';
  nok $sheet.remove-set( :category<__test-accounting>, :set<profile>),
     'profile set not removed';
  ok $sheet.remove-set( :category<__test-accounting>, :set<credentials>),
     '.remove-set()';

  ok $sheet.add-set( :category<__test-accounting>, :set<credentials>),
     '.add-set()';
  ok $sheet.add-set( :category<__test-accounting>, :set<profile>),
     '.add-set()';

  $sheet.delete-page(:name<tstsheet2>);
  $sheet.save;

  if $*DISTRO.is-win {
    skip 'No idea for store locations on windows yet', 1;
  }

  else {
    my Str $qa-path = $qa-types.qa-path( '__login', :sheet);
    ok $qa-path.IO.r, '.save() __login';
  }

  $sheet.save-as('__login2');
  if $*DISTRO.is-win {
    skip 'No idea for store locations on windows yet', 1;
  }

  else {
    my Str $qa-path = $qa-types.qa-path( '__login2', :sheet);
    ok $qa-path.IO.r, '.save-as() __login2';
  }

  my $c := $sheet.clone;
  my @sheets = <tstsheet3 tstsheet1>;
  for $c -> Hash $page {
#    note $page.keys;
    is $page<name>, @sheets.shift, "page iterator $page<name>";
  }

  $sheet .= new(:sheet-name<__login2>);
  ok $sheet.remove, '__login2 deleted';

  # cannot remove unloaded sheets
  $sheet .= new(:sheet-name<__login>);
  ok $sheet.remove, '__login removed';
}

#-------------------------------------------------------------------------------
my QA::Category $category .= new(:category-name<__test-accounting>);
$category.remove;

done-testing;

#-------------------------------------------------------------------------------
# create some category data with some sets
sub make-category ( ) {
  my QA::Category $category .= new(:category-name<__test-accounting>);

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
  $question.encode = True;
  $question.invisible = True;
  $set.add-question($question);

  # add set to category
  $category.add-set($set);

  # 2 set
  $set .= new(:name<profile>);
  $set.description = 'Extra info for account';

  # 1st question and add to set
  $question .= new(:name<waddress>);
  $question.description = 'Work Address';
  $question.required = True;
  $set.add-question($question);

  # add set to category
  $category.add-set($set);

  # save category
  $category.save;
}
