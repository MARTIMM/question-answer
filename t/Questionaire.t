use v6.d;
use Test;

use QA::Questionaire;
use QA::Set;
use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
# set a few values before initializing
#enum DE <SET SHEET UDATA>;
#my @dirs = <t/Data/Sets t/Data/Qsts t/Data/User>;
#for @dirs -> $d {
#  mkdir $d, 0o700 unless $d.IO.e;
#}

given my QA::Types $qa-types {
  .data-file-type(QAYAML);
  .set-root-path('t/Data');
}

# create some sets
make-sets();

my QA::Questionaire $qst .= new(:qst-name<login>);


#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $qst, QA::Questionaire, '.new(:sheet-name)';
}
#-------------------------------------------------------------------------------
subtest 'Add pages and sets', {

  ok $qst.add-page('tstsheet2'), '.add-page() tstsheet2';

  ok $qst.add-page('tstsheet3'), '.add-page() tstsheet3';
  ok $qst.add-set( 'tstsheet3', 'credentials'), '.add-set()';
  ok $qst.add-set( 'tstsheet3', 'profile'), '.add-set()';

  ok $qst.add-page(
    'tstsheet1',
    :title("Test Page 1"),
    :description("Description jzh glfksd slfdjg sdfgl jsfdg lsdfg jhsdlfgj sdfg lsdkj sdgljshdfg ls dfj sdf glsjfdg sdflg ksdlfgj sdfg sdflkhsdf gsdfkggh"
    )
  ), '.add-page() tstsheet1';

  ok $qst.add-set( 'tstsheet1', 'credentials'), '.add-set()';
  nok $qst.add-set( 'tstsheet1', 'credentials'), 'cannot add same set';
  ok $qst.add-set( 'tstsheet1', 'profile'), '.add-set()';

  my $c := $qst.clone;
  my @sheets = <tstsheet2 tstsheet3 tstsheet1>.reverse;
  for $c -> Hash $page {
    is $page<page-name>, @sheets.pop, "page iterator $page<page-name>";
  }
}

#-------------------------------------------------------------------------------
subtest 'Save and load', {

  $qst.width = 400;
  $qst.height = 700;
  $qst.button-map = %( :cancel("stopt u maar"), :save-quit<klaar!>);

  $qst.save;
  ok "t/Data/login.yaml-qaqst".IO ~~ :e, '.save() login';

  $qst.save-as('login2');
  ok "t/Data/login2.yaml-qaqst".IO ~~ :e, '.save-as() login2';

  $qst .= new(:qst-name<login>);
  is $qst.width, 400, 'reload sheet';
  my QA::Set $set .= new(
    :set-data($qst.get-set( 'tstsheet1', 'credentials'))
  );
  is $set.description, 'Name and password for account', 'reload set';
  my QA::Question $pw = $set.get-question('password');
  is $pw.description, 'Password for username', 'reload password';
}

#-------------------------------------------------------------------------------
subtest 'replace sets and pages', {

  # change credential set
  change-sets();

  my QA::Questionaire $qst2 .= new(:qst-name<login2>);
  nok $qst2.add-set( 'tstsheet3', 'credentials'), 'set already there';
  ok $qst2.add-set( 'tstsheet3', 'credentials', :replace), 'replaced set';
  $qst2.width = 300;
  $qst2.save;

  $qst2 .= new(:qst-name<login2>);
  is $qst2.width, 300, 'reload changed sheet';
  my QA::Set $set .= new(
    :set-data($qst2.get-set( 'tstsheet3', 'credentials'))
  );
  is $set.description, 'Name and password', 'reload changed set';
  my QA::Question $pw = $set.get-question('password');
  is $pw.description, 'Password', 'reload changed password';
}

#-------------------------------------------------------------------------------
subtest 'remove sets and pages', {
#\  show-pages($qst);
  ok $qst.remove-set( 'tstsheet3', 'credentials'), '.remove-set()';
#  show-pages($qst);

  nok $qst.remove-set( 'tstsheet3', 'creds'), 'creds set not added';
  ok $qst.remove-set( 'tstsheet3', 'profile'), 'profile removed';

  $qst.remove-page('tstsheet2');
#  show-pages($qst);
}


#-------------------------------------------------------------------------------
subtest 'remove sheet', {

  $qst .= new(:qst-name<login2>);
  ok $qst.remove, 'login2 deleted';

  # cannot remove unloaded sheets
  $qst .= new(:qst-name<login>);
  ok $qst.remove, 'login removed';
  nok $qst.remove, 'login already removed';
  ok "t/Data/login.yaml-qaqst".IO ~~ :!e, 'file removed';
}

#-------------------------------------------------------------------------------
my QA::Set $set .= new(:set-name<credentials>);
$set.remove;
$set .= new(:set-name<profile>);
$set.remove;

done-testing;


#-------------------------------------------------------------------------------
# create a few sets
sub make-sets ( ) {

  # 1 set
  my QA::Set $set .= new(:set-name<credentials>);
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
  $set .= new(:set-name<profile>);
  $set.description = 'Extra info for account';

  # 1st question and add to set
  $question .= new(:name<work-address>);
  $question.description = 'Work Address';
  $question.required = True;
  $set.add-question($question);

  # save 2nd set
  $set.save;
}

#-------------------------------------------------------------------------------
# modify sets
sub change-sets ( ) {

  my QA::Set $set .= new(:set-name<credentials>);
  $set.description = 'Name and password';

  # 1st question and add to set
  my QA::Question $question .= new(:name<username>);
  $question.description = 'Username';
  $question.required = True;
  $set.add-question( $question, :replace);

  # 2nd question and add to set
  $question .= new(:name<password>);
  $question.description = 'Password';
  $question.required = True;
  $question.invisible = True;
  $set.add-question( $question, :replace);

  # save changes
  $set.save;
}

#-------------------------------------------------------------------------------
multi sub show-set( Str:D $set-name ) {

  note " ";
  my QA::Set $set .= new(:$set-name);
  my $c := $set.clone;
  for $c -> QA::Question $q {
    for $q.qa-data.kv -> $k, $v {
      note "$k => $v";
    }
    note " ";
  }
}

#-------------------------------------------------------------------------------
multi sub show-set( Hash:D $set ) {

  note "\n  Set '$set<set-name>':";
  for $set.kv -> $sk, $sv {
    next if $sk eq 'set-name';

    if $sk eq 'questions' {
      for @($set<questions>) -> $q {
        note "\n    Question '$q<name>':";
        for $q.kv -> $qk, $qv {
          next if $qk eq 'name';
          note "      $qk => $qv";
        }
#        note " ";
      }
    }
    else {
      note "    $sk => $sv";
    }
#    note " ";
  }
}

#-------------------------------------------------------------------------------
sub show-pages( QA::Questionaire $qst ) {

  note "\nPage $qst:";
  my $c := $qst.clone;
  for $c -> Hash $page {
    note "\nPage '$page<page-name>':";
    for $page.kv -> $k, $v {
      next if $k eq 'page-name';

      if $k eq 'sets' {
        for @($page<sets>) -> $set {
          show-set($set);
        }
      }
      else {
        note "  $k => $v";
      }
    }
#    note " ";
  }
}
