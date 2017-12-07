###
elemicaSuggest 0.9.2
(c)2014 Elemica - Licensed under the terms of the Apache 2.0 License.
###
##
# elemicaSuggest - Simple typeahead suggestions.
#
# The elemicaSuggest function provides a simple, simple typeahead suggest
# that simply monitors an input, calls a function to get some suggestions,
# and adds a ul next to the input with the suggestions.
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
# - buildMarkerRegExp: A function that is given the current search term, and is
#   expected to return a regular expression whose capturing groups will be used
#   to mark the suggestions with the class `match`. For example, if the search
#   term was "hello", you could return /(hello)/ to mark all instances of that
#   word in all suggestions with the `match` class. Each match is wrapped in a
#   `span`.
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
      KEY_N = 78
      KEY_P = 80
      LEFT_ARROW = 37
      UP_ARROW = 38
      RIGHT_ARROW = 39
      DOWN_ARROW = 40
      ENTER = 13
      TAB = 9
      BACKSPACE = 8

      SHIFT = 16
      CTRL = 17
      ALT = 18
      OS_LEFT = 91
      OS_RIGHT = 92

      NON_PRINTALBE_KEYS = [SHIFT, CTRL, ALT, OS_LEFT, OS_RIGHT, TAB, LEFT_ARROW, RIGHT_ARROW]

      # This function returns true if selection box is active
      # and user is selecting one of the options
      isSelectingSuggestion = -> $(".suggestions").is(":visible")

      suggestFunction = options.suggestFunction || (term, _) ->
        console?.warn "No suggest function defined."

      minimumSearchTermLength = if options.minimumSearchTermLength?
        options.minimumSearchTermLength
      else
        2

      $valueInput = options.valueInput || $("<input />")

      selectionIndicatorTarget = options.selectionIndicatorTarget || ($target) -> $target

      noMatchesMessage = options.noMatchesMessage || $(@first()).data('no-matches')

      afterSuggest = options.afterSuggest || noop

      afterSelect = options.afterSelect || noop

      noSuggestionMatched = options.noSuggestionMatched || -> true

      buildMarkerRegExp = options.buildMarkerRegExp || noop

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
          .trigger("focus")
        removeSuggestions(element)

        selectionIndicatorTarget( $(element) ).addClass("has-selection")

      currentHighlightedDisplayText = (element) ->
        $(element).parent().find(".suggestions > .active").text()

      markMatches = (markerRegExp) -> (textToMark) ->
        markedContent = []
        currentIndex = 0

        while latestMatch = markerRegExp.exec(textToMark)
          # If we have a zero-width match, bail before we infini-loop.
          break if latestMatch[0].length == 0

          prefix = textToMark.substring(currentIndex, latestMatch.index)

          matches =
            for i in [1...latestMatch.length]
              $('<span />')
                .addClass('match')
                .text(latestMatch[i])

          currentIndex = latestMatch.index + Math.max(latestMatch[0].length, 1)

          markedContent.push document.createTextNode(prefix)
          markedContent.push.apply markedContent, matches

          # Non-global RegExps will repeatedly match from the beginning; we
          # break out in that case to avoid an infinite loop.
          break unless markerRegExp.global

        markedContent.push document.createTextNode(textToMark.substring(currentIndex))

        markedContent

      populateSuggestions = (element, markMatchRegExp) -> (suggestions) ->
        $suggestionsList = $(element).siblings(".suggestions")

        if $suggestionsList.length == 0
          $suggestionsList = $("<ul />")
            .addClass("suggestions")

          $(element).parent().append($suggestionsList)

        matchMarker = if markMatchRegExp? then markMatches(markMatchRegExp)

        $suggestionsList.empty().append(
          for suggestion in suggestions
            do (suggestion) ->
              $suggestionLi = $("<li />")

              if matchMarker?
                $suggestionLi.append matchMarker(suggestion.display)
              else
                $suggestionLi.text suggestion.display

              $suggestionLi
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

      handleUserInput = (that, event) ->
        $valueInput.val("")
        $target = $(event.target)
        selectionIndicatorTarget($target).removeClass("has-selection")
        searchTerm = $.trim($target.val())

        if searchTerm.length >= minimumSearchTermLength
          markMatchRegExp = buildMarkerRegExp(searchTerm)

          suggestFunction searchTerm, populateSuggestions(that, markMatchRegExp)
        else
          removeSuggestions(that)

      @each ->
        $(this).attr 'autocomplete', 'off'

        $(this).on 'blur', (event) ->
          $target = $(event.target)

          if isSelectingSuggestion() && $target.val().toLowerCase() == currentHighlightedDisplayText(this).toLowerCase()
            selectHighlighted(this)
          else
            removeSuggestions(this)

          if $valueInput.val() == ""
            if noSuggestionMatched($target.val(), afterSelect)
              originalValue = $target.val()
              $target.val("")
              afterSelect(null) if originalValue != ""

        $(this).on 'keydown', (event) =>
          key = event.which
          ctrlPressed = event.ctrlKey

          if key is UP_ARROW || key is DOWN_ARROW ||
             (ctrlPressed && (key is KEY_P || key is KEY_N))
            event.preventDefault()
          else if event.which == ENTER && isSelectingSuggestion()
            event.preventDefault()
          else if event.which == TAB && isSelectingSuggestion()
            selectHighlighted(this)
          else if event.which == BACKSPACE && $valueInput.val() != ""
            $valueInput.val("")
            $(event.target).val("")
            afterSelect(null)

        $(this).on 'keyup', (event) =>
          key = event.which
          ctrlPressed = event.ctrlKey

          switch
            when key is UP_ARROW || (ctrlPressed && key is KEY_P)
              highlightPrevious(this)
            when key is DOWN_ARROW || (ctrlPressed && key is KEY_N)
              highlightNext(this)
            when key is ENTER
              selectHighlighted(this)
            # Ignore other non-printable keys.
            when key not in NON_PRINTALBE_KEYS
              handleUserInput(this, event)

        $(this).on 'paste', (event) =>
          handleUserInput(this, event)

)(jQuery)
