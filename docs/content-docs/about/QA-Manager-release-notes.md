---
title: About MongoDB Driver
nav_menu: default-nav
sidebar_menu: sidebar-about
layout: sidebar
---
# Release notes

See [semantic versioning](http://semver.org/). Please note point 4. on that page: **_Major version zero (0.y.z) is for initial development. Anything may change at any time. The public API should not be considered stable._**

#### 2020-12-06 0.13.1
* Split package into two. Now called **QA** and **QA::Manager**. **QA** is meant for using the forms by a user's application while **QA::Manager** is meant to create and manage these forms. A separation of the two makes the most used one, **QA**, somewhat lighter. Both packages wil continue their versions at 0.13.1. The [website is now at](https://martimm.github.io/question-answer/).

##### previous entries are dropped as if the manager did not exist before 😇
