---
title: Configuration
nav_menu: default-nav
sidebar_menu: sidebar-config
layout: sidebar
---
# Extensions in QA

This document is describing the extensions used by the **QA** and **QA::Manager** module.


## Configuration and data files

 In the early days the configurations of several parts were stored using several formats. The user could then select the proper format.

The formats are `TOML`, `JSON` and `YAML`. The config files had their extensions set to `.toml`, `.json` and `.yaml` respectively. The files also described different content for questions, sets and Questionnares. To keep them apart, they were placed in separate directories. This made the software a bit more complex.

The solution to all this is to make special extensions which reflect both format and content. Examples of these are `.yaml-qaqst` for YAML formatted Questionnares and `.toml-qadata` for TOML formatted result data.

All data can now also be placed in one directory. By default, this will be something like `$*HOME/.config/$basename`, where the basename is derived from the programname whitout its extension.

See also a small document about [locations](./locations.html).



## Script extension

To use a questionaire in some application to define a configuration or what other reason there may be, initialize
