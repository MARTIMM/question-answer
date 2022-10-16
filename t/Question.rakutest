use v6.d;
use Test;

use QA::Question;
use QA::Types;

#-------------------------------------------------------------------------------
my QA::Question $q .= new(
  :name<username>, :qa-data(%(:default<mickey>))
);

#-------------------------------------------------------------------------------
subtest 'ISO-Test', {

  isa-ok $q, QA::Question;
}

#-------------------------------------------------------------------------------
subtest 'Manipulations', {
  $q.description = 'Username of account';
  $q.required = True;

  my Hash $x = $q.qa-data;
  is $x<description>, 'Username of account', '.description()';
  ok $x<required>, '.required()';
  is $x<default>, 'mickey', '.new()';
  is $x<fieldtype>, QAEntry, 'default field type';

#  note $q.qa-data;
}

#-------------------------------------------------------------------------------
done-testing
