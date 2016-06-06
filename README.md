# elemica-suggest

[![Build Status](https://travis-ci.org/elemica/elemica-suggest.svg)](https://travis-ci.org/elemica/elemica-suggest)

This is elemica-suggest, a simple typeahead/suggest library that makes your life easy by doing less
instead of more. Other suggestion and typeahead libraries provide a lot of drop-in styling that you
may or may not want in your application. If you do want that styling, go for it. If you don't, we
encourage you to try out elemica-suggest, which just provides you some semantic markup that you can
style how you please.

## Using

Using Elemica Suggest is as simple as invoking the `elemicaSuggest` function on an input that the
user will be typing in. For example, given the following markup:

```html
<form>
  <input type="text" id="user-name-typeahead">
  <input type="hidden" id="user-id">
</form>
```

Let's assume you have a REST API that will return objects that will return elemica-suggest
suggestion objects as JSON. You would probably want to set up elemica-suggest like so:

```javascript
function suggestFunction(userInput, callback) {
  $.ajax({
    url: '/api/v1/user-suggestions',
    success: callback
  });
}

$("#user-name-typeahead").elemicaSuggest({
  suggestFunction: suggestFunction,
  valueInput: $("#user-id")
});
```

This would wire up the text input to be a typeahead, and would add an unordered list
containing the suggestions returned by your API below the input. For example,

```html
<ul>
  <li>Suggestion 1</li>
  <li>Suggestion 2</li>
</ul>
```

May be added below the input if the suggestFunction returns those values. You have the freedom
to style that `ul` however you like.

### CSS Classes

The elemica-suggest library is pretty unstyled when you first drop it in. This
is an intentional decision. You are the one building your app, and you should
be the one to dictate what it looks like - typeahead suggestions and all. To
facilitate this we use a few different CSS classes to help you with your
styling.

* **suggestions** is applied to the `ul` that contains the suggestions that are being made.
* **active** is applied to the `li` inside `ul.suggestions` that is currently selected by the
  user. A suggestion can become active by the user using the up or down arrow
  keys, or by using Ctrl-N or Ctrl-P, or by hovering over the `li` with their
  mouse.
* **has-selection** is applied to an element to indicate that a selection has been made. By default
  this element is the text field itself, but if you have need you can provide a value for the
  `selectionIndicatorTarget` parameter (see below) and change where this class is applied.
* **invalid-text** is applied to a suggestion `li` when that suggestion `li` is a message informing
  the user that there are no matches for their query.
* **match** is applied to spans inside suggestions when part of the suggestion
  is matched by a capturing group in the regular expression returned by the
  `buildMarkerRegExp` function, if provided.

### Using Dev Tools

If you want to use browser's Dev tools to inspect generated HTML you must disable support for `blur` event
as in other case the whole generated HTML content disappear as soon as you switch to the Dev tools.

To disable this, lunch the below command in JavaScript console:

```javascript
$("#user-name-typeahead").off('blur')
```

Thus will allow switching to the Dev tools and inspect the generated content.

## Suggestion Format

In your `suggestFunction` that you pass into `elemicaSuggest`, you must provide a function
that takes in two parameters:

1. The user's input so far.
2. The callback to use when you have suggestions.

The callback function will expect to take in an array of JavaScript objects that we call
**suggestion objects**. The suggestion objects have the following key values:

* **display** (required) - The display text for the suggestion. This is what the user sees.
* **value** (required) - The value text for the suggestion. This is what's plugged in to the hidden
  input when the user makes a selection.
* **image** (optional) - An image URL for an image to be displayed alongisde the suggestion in
  the list of suggestions.
* **metadata** (optional) - Some text to be displayed after the display text. Will be wraped in a
  span with the class "metadata".

## Available elemicaSuggest options

The following options are available on the elemicaSuggest function:

- suggestFunction: The function that takes in a string and a callback
  retrieves some suggestions and invokes the callback passing in the
  suggestions as a parameter. The return value of this function should be
  an array of suggestion objects, where suggestion objects contain the following
  keys:
  - display: The display text for the suggestion.
  - value: The value to be stuffed into valueInput if the suggestion is selected
  - image: (optional) An image associated with the suggestion.
  - metadata: (optional) Some additional metadata text associated with the suggestion.
- valueInput: A jQuery object representing the DOM node which will receive
  the value selected by the user.
- minimumSearchTermLength: (optional) The minimum number of characters the end-user needs
  to type in the text box before elemica-suggest starts making suggestions.
- buildMarkerRegExp: (optional) A function that is given the current search
  term, and is expected to return a regular expression whose capturing groups
  will be used to mark the suggestions with the class `match`. For example, if
  the search term was "hello", you could return /(hello)/ to mark all instances
  of that word in all suggestions with the `match` class. Each match is wrapped
  in a `span`.
- selectionIndicatorTarget: (optional) A function that takes in a jQuery object that represents
  the input and operates on that object to return a jQuery object of the element(s)
  that will receive the has-selection CSS class when a selection is made. By default
  this is a function that just returns the target element of elemicaSuggest.
- noMatchesMessage: (optional) The message that should be displayed when the suggestFunction returns
  no hits. It will default to the contents of the data-no-matches attribute on the target
  element of elemicaSuggest if not specified.
- afterSuggest: (optional) A function to be invoked after suggestions have been populated.
- afterSelect: (optional) A function to be invoked after a selection has been made or cleared. In the
  event a selection has been made, we pass in the suggestion object representing that suggestion. In
  the event that a selection has been cleared, we pass in `null`. This callback is invoked on each
  selection the user makes, including identical selections.
- noSuggestionMatched: (optional) A function to be invoked after user left typeahead input and no
  suggestion matched entered value. If function returns truthy, input will be cleared. That's the
  default behaviour. If function returns falsey, input will remain filled. Also, falsey value returned
  from callback leds to breaking callbacks chain and afterSelect callback is not going to be invoked. 
  noSuggestionMatched accepts two parameters - the unmatched input field value and reference 
  to afterSelect in case developer wants to invoke it manually.

## Developing

The elemica-suggest library uses npm as its primary development tool, but is only set up for
publishing to bower, as it is a front-end library. While working on elemica-suggest there are
a few npm commands that will probably be of interest.

To set up your environment for development, you will want to run:

```
$ npm install
```

Which will install the neccicary libraries required to test elemica-suggest. to actuall run
specs, you can run:

```
$ npm test
```

And, finally, you can run the dist command to build the distributable JavaScript:

```
$ npm run-script dist
```

The dist script is run automatically when you invoke test, and because you're running tests
all the time, that means you should rarely, if ever, need to invoke dist directly, right?
