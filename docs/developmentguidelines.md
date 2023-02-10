# Development Guidelines

This module has been designed with modularity in mind. Reusable functionality has been intentionally split into separate functions. For example, the `Invoke-AzdoApi` function is the main REST API caller, standardising the way this module interacts with the Azure DevOps API.

> Main logic is stored under _.\scripts_ folder

## Practical Design Considerations

If you are developing new functionality, keep the following in mind:

### Reusable functionality

If the logic you are developing has the potential to be duplicated across many functions, consider putting it into its own function.

### Keep unit testing in mind

Unit testing in PowerShell is probably more painful than with other languages. To ease testing efforts, consider wrapping even basic functionality around a function. This will allow you to mock that functionality and save you from duplicating testing logic across multiple scripts (especially where functions call each other).

### Module scoped variables?

Put them in the _.psm1_.
