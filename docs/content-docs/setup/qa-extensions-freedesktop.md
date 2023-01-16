---
title: Configuration
nav_menu: default-nav
sidebar_menu: sidebar-config
layout: sidebar
---
# Extensions in QA and QA::Manager

## Configuration and data files

 In the early days the configurations of several parts were stored using several formats. The user could then select the proper format.

The formats are `TOML`, `JSON` and `YAML`. The config files had their extensions set to `.toml`, `.json` and `.yaml` respectively. The files also described different content for questions, sets and questionnaires. To keep them apart, they were placed in separate directories. This made the software a bit more complex.

The solution to all this is to make special extensions which reflect both format and content. Examples of these are `.yaml-qaqst` for YAML formatted questionnaires and `.toml-qadata` for TOML formatted result data.

All data can now also be placed in one directory. By default, this will be something like `$*HOME/.config/$basename`, where the basename is derived from the programname whitout its extension.

See also a small document about [locations](./locations.html).



## Script extension

To use a questionnaire in some application to define a configuration or what other reason there may be, roughly the following steps are needed;

* Initialize QA. This means, setting the locations and extensions of files when the default is not sufficient.
* Create an empty window.
* Choose one of the possible Gui classes e.g. **QA::Gui::PageSimpleWindow** and instantiate using the empty window.

These steps are simple enough to make a simple program capable to handle all sorts of invoices when no particular program is available. The program is called **qascript.raku**. It reads a file with info to open the proper invoice. This file has the extension `.qascript`. Its format and contents is described with the program.
