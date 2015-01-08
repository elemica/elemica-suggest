###
elemicaSuggest 0.7.1-SNAPSHOT.
(c)2014 Elemica - Licensed under the terms of the Apache 2.0 License.
###
##
# elemicaSuggest - Simple typeahead suggestions.
#
# The elemicaSuggest function provides a simple, simple typeahead suggest
# that simply monitors an input, calls a function to get some suggestions,
# and add a ul next to the input with the suggestions.
#
# For configuration the elemicaSuggest call takes in an object literal that
# defines the following options:
# - suggestFunction: The function that takes in a string and a callback
#   retrieves some suggestions and invokes the callback passing in the
#   suggestions as a parameter. The return value of this function should be
#   an array of suggestion objects, where suggestion objects contain the following
#   keys:
#   - display: The display text for the suggestion.
#   - value: The value to be stuffed into valueInput if the suggestion is selected
#   - image: (optional) An image associated with the suggestion.
#   - metadata: (optional) Some additional metadata text associated with the suggestion.
# - minimumSearchTermLength: The minimum number of characters the user is required to type
#   to initate a typeahead search. Defaults to 2.
# - valueInput: A jQuery object representing the DOM node which will receive
#   the value selected by the user.
# - selectionIndicatorTarget: A function that takes in a jQuery object that represents
#   the input and operates on that object to return a jQuery object of the element(s)
#   that will receive the has-selection CSS class when a selection is made. By default
#   this is a function that just returns the target element of elemicaSuggest.
# - noMatchesMessage: The message that should be displayed when the suggestFunction returns
#   no hits. It will default to the contents of the data-no-matches attribute on the target
#   element of elemicaSuggest if not specified.
# - afterSuggest: A function to be invoked after suggestions have been populated.
# - afterSelect: A function to be invoked after a selection has been made. Will pass in the entire
#   suggestion object that was selected by the user.
# - noSuggestionMatched: (optional) A function to be invoked after user left typeahead input and no
#   suggestion matched entered value. If function returns truthy, input will be cleared. That's the
#   default behaviour. If function returns falsey, input will remain filled. Also, falsey value returned
#   from callback leds to breaking callbacks chain and afterSelect callback is not going to be invoked. 
#   noSuggestionMatched accepts two parameters - the unmatched input field value and reference 
#   to afterSelect in case developer wants to invoke it manually.
##
(($) ->
  noop = ->

  $.fn.extend
    elemicaSuggest: (options = {}) ->
      UP_ARROW = 38
      DOWN_ARROW = 40
      ENTER = 13
      TAB = 9
      BACKSPACE = 8

      # This function returns true if selection box is active
      # and user is selecting one of the options
      isSelectingSuggestion = -> $(".suggestions").is(":visible")

      suggestFunction = options.suggestFunction || (term, _) ->
        console?.warn "No suggest function defined."

      minimumSearchTermLength = options.minimumSearchTermLength || 2

      $valueInput = options.valueInput || $("<input />")

      selectionIndicatorTarget = options.selectionIndicatorTarget || ($target) -> $target

      noMatchesMessage = options.noMatchesMessage || $(@first()).data('no-matches')

      afterSuggest = options.afterSuggest || noop

      afterSelect = options.afterSelect || noop
      
      noSuggestionMatched = options.noSuggestionMatched || -> true

      removeSuggestions = (element) ->
        $(element).siblings(".suggestions").remove()

      # This is the general implementation for highlighting another function.
      #
      # - element: The dom node whose input we're currently suggesting on.
      # - otherCalcFunc: A function that takes in the jQuery object for the currently
      #   selected item in the suggest box, and operates on it to produce the
      #   jQuery object for what suggestion should be selected.
      highlightAnother = (element, otherCalcFunc) ->
        $currentActive = $(element).parent().find(".suggestions > .active")
        $nextElement = otherCalcFunc($currentActive)

        if $currentActive.length && $nextElement.length
          $currentActive.removeClass("active")
          $nextElement.addClass("active")
        else if ! $currentActive.length
          $(element).parent().find(".suggestions > li:first-child").addClass("active")

      highlightNext = (element) ->
        highlightAnother element, ($currentActive) -> $currentActive.next()

      highlightPrevious = (element) ->
        highlightAnother element, ($currentActive) -> $currentActive.prev()

      selectHighlighted = (element) ->
        $(element)
          .parent()
            .find(".suggestions .active")
              .trigger("element-selected")
            .end()
          .end()
          .trigger("blur")
          .trigger("focus")

        selectionIndicatorTarget( $(element) ).addClass("has-selection")

      populateSuggestions = (element) -> (suggestions) ->
        $suggestionsList = $(element).siblings(".suggestions")

        if $suggestionsList.length == 0
          $suggestionsList = $("<ul />")
            .addClass("suggestions")

          $(element).parent().append($suggestionsList)

        $suggestionsList.empty().append(
          for suggestion in suggestions
            do (suggestion) ->
              $suggestionLi = $("<li />").text(suggestion.display)
                .on('mousedown element-selected', ->
                  $(element).val( suggestion.display )
                  $valueInput.val( suggestion.value )
                  afterSelect( suggestion )
                )
                .on('mouseover', ->
                  $(this)
                    .siblings()
                      .removeClass("active")
                    .end()
                    .addClass("active")
                )

              if suggestion.image?
                $suggestionLi.prepend(
                  $("<img />").attr("src", suggestion.image)
                )

              if suggestion.metadata?
                $suggestionLi.append(
                  $("<span />").text(suggestion.metadata).addClass("metadata")
                )

              $suggestionLi
        ).find("li:first-child").addClass("active")

        if suggestions.length == 0
          $suggestionsList.append(
            $("<li />")
              .text(noMatchesMessage)
              .addClass("invalid-text")
          )

        afterSuggest()

      @each ->
        $(this).attr 'autocomplete', 'off'

        $(this).on 'blur', (event) ->
          $target = $(event.target)
          removeSuggestions $target

          if $valueInput.val() == ""
            if noSuggestionMatched($target.val(), afterSelect)
              $target.val("")
              afterSelect(null)

        $(this).on 'keydown', (event) =>
          if event.keyCode == UP_ARROW || event.keyCode == DOWN_ARROW
            event.preventDefault()
          else if event.keyCode == ENTER && isSelectingSuggestion()
            event.preventDefault()
          else if event.keyCode == TAB && isSelectingSuggestion()
            selectHighlighted(this)
          else if event.keyCode == BACKSPACE && $valueInput.val() != ""
            $valueInput.val("")
            $(event.target).val("")
            afterSelect(null)

        $(this).on 'keyup', (event) =>
          switch event.keyCode
            when UP_ARROW
              highlightPrevious(this)
            when DOWN_ARROW
              highlightNext(this)
            when ENTER
              selectHighlighted(this)
            else
              $valueInput.val("")
              $target = $(event.target)
              selectionIndicatorTarget($target).removeClass("has-selection")
              searchTerm = $.trim($target.val())

              if searchTerm.length >= minimumSearchTermLength
                suggestFunction searchTerm, populateSuggestions(this)
              else
                removeSuggestions(this)
)(jQuery)
