# Introduction

This PowerShell module provides and abstraction layer around existing Azure DevOps API calls. It has been developed to enable Azure DevOps interaction via the command line - both for individual use, and use within other automation mechanisms (like Azure Pipelines).

## Getting Started

TODO: Installation process (internal package feed), other dependencies etc.

## Contribute

Contributions are welcome! Before doing so, please consider the following guidelines:

[Development Guidelines](.\docs\developmentguidelines.md)

[Module Design](.\docs\moduledesign.md)

## Build and Test

TODO: Describe and show how to build your code and run the tests.

## Credits

This module leverages some of the concepts and convention put forward by [devblackops/Stucco](https://github.com/devblackops/Stucco) - author of the PowerShellBuild module, and maintainer of [psake](https://github.com/psake/psake). For more information, see the [Stucco README](https://github.com/devblackops/Stucco#stucco).

In addition, kudos are given to the following projects for simplifying and standardising the PowerShell build
process:

[psake/PowerShellBuild](https://github.com/psake/PowerShellBuild)

The PowerShellBuild module is used as a common scaffolding for standard build/test/publish tasks. The author of this module proposes a standard approach to PowerShell build practices that drastically reduces the overhead of writing (and re-writing) common build and test scaffolding.

[RamblingCookieMonster/PSDepend](https://github.com/RamblingCookieMonster/PSDepend)
This module simplifies dependency handling in PowerShell by providing a common, configuration-driven approach. Module dependencies (both external and internal) are declared in a single place and handled in a consistent way during build time.

[RamblingCookieMonster/BuildHelpers](https://github.com/RamblingCookieMonster/BuildHelpers)
This module is used to standardise the build process and prep the environment by providing environment-scoped variables that can be used at build time.
