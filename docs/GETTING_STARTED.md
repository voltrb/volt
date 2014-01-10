# Getting Started

Volt relies on a few concepts to take make web development faster and easier.  The first of these is reactive programming.  Data on the front and back end is stored in models.  Instead of manually updating a page when the data changes, the page is coded using a handlebars like templating language which automatically updates when the data changes.

## Reactive Values

The key to making these updates happen is something we call "Reactive Values."  A ReactiveValue wraps another v