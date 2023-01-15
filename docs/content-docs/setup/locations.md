---
title: Configuration
nav_menu: default-nav
sidebar_menu: config-sidebar
layout: sidebar
---
# Locations

There are several locations involved where questionaires and categories are stored. The results of the query is stored at a standard location if not changed.

Using definitions of [Free Desktop](https://freedesktop.org/wiki/);
* Sets, Questionaires and Data (answers returned from the questionaires) are stored in files placed into the users configuration environment `$*HOME/.config/<modified $*PROGRAM-NAME>`. On windows, another path is used; `C:\dataDir\<modified $*PROGRAM-NAME>`.
* The Questionaire is also filled in from the data file before presentation if there is any data.
* The root is to be set (if default is undesirable) just before accessing any QA class to prevent using wrong config files or get non-existing configuration files.








<!--
However, it is possible to change the paths to other locations. This is important when you want to install a module or package making use of its own quetionaires but not yet placed in the QAManager environment. Because the module installation program `zef` is not aware of any files from other locations than those in the `META6.json` configuration, other actions must be executed to get the sheets at the right locations. Several methods exist to install the modules set and sheet configurations;

1) Write an installation module (`Build.pm6`) which installs the sheets at the proper location when installing your package. An example installation module to install categories and sheets is shown below;

```
use v6.d;

use QAManager::Set;
use QAManager::Question;
use QAManager::Category;
use QAManager::QATypes;

unit class Build;

method build( Str $dist-path - - > Int ) {
  make-categories;
  make-sheets;

  1;
}

make-categories ( ) {

  # create category
  my QAManager::Category $category .= new(:category-name('accounting'));

  # create a set
  my QAManager::Set $set .= new(:name<credentials>);
  $set.description = 'Set name and password for a new account';

  # 1st question and add to set
  my QAManager::Question $question .= new(:name<username>);
  $question.description = 'Username of account';
  $question.required = True;
  $set.add-question($question);

  # 2nd question and add to set
  $question .= new(:name<password>);
  $question.description = 'Password for username';
  $question.required = True;
  $question.invisible = True;
  $set.add-question($question);

  # add set to category
  $category.add-set($set);

  # create another set
  $set .= new(:name<profile>);
  # add some questions ...
  $category.add-set($set);

  # and save like an archive. category with sets are now saved
  # in QAManagers environment
  $category.save;

  # create more categories ...
}

make-sheets ( ) {
  # create a questions sheet holding the sets
  my QAManager::Sheet $sheet .= new(:sheet-name<login>);
  $sheet.display = QADialog;
  $sheet.button-map = %( "save-quit": "login");

  $sheet.new-page(:name<Login>);
  $sheet.add-set( :category<accounting>, :set<credentials>);
  $sheet.save;

  # create more sheets ...
}

```

2) Keep the sheets in the resources directory and install them when programs or a module is accessed the first time.

-->
