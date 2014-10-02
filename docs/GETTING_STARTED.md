# Getting Started

Volt relies on a few concepts to take make web development faster and easier.  The first of these is reactive programming.  Data on the front and back end is stored in models.  Instead of manually updating a page when the data changes, the page is coded using a templating language which automatically updates when the data changes.

## Bindings and Models

This automaic updating is done via bindings and models.  In Volt app's all data is stored in a model.  From your html, you can bind things like attributes and text to a value in a model.

### Name Example

```html
<label>Name:</label>
<input type="text" value="{page._name}" />
<p>Hello {page._name}</p>
```

In the example above, our model is called page (more about page later).  Any time a user changes the value of the field, page._name will be updated to the fields value.  When page._name is changed, the fields value changes.  Also when ```page._name``` changes, the page will show the text "Hello ..." where ... is the value of page._name.  These "two-way bindings" help us eliminiate a lot of code by keeping all of our application state in our models.  Data displayed in a view is always computed live from the data in the models.

### Meal Cost Splitter Example

```html
<label>Cost:</label><input type="text" value="{page._cost}" /><br />
<label>People:</label><input type="text" value="{page._people}" /><br />
<p>Cost Per Person: {page._cost.to_f / page._people.to_f}</p>
```
In this example, a user can enter a cost and a number of people.  When either changes, the Cost Per Person will update.

###
