chai = require 'chai'
assert = require("assert")
jsdom = require("jsdom");
{ JSDOM } = jsdom;
jsdomWindow = new JSDOM().window
jQuery = require('jquery')(jsdomWindow)
$ = jQuery

clipboard = undefined
clipboardData =
  setData: (text) ->
    clipboard = text
    
  getData: (_) ->
    clipboard
  
window = jsdomWindow
window.clipboardData = clipboardData
document = jsdomWindow.document
fs = require 'fs'

eval(fs.readFileSync('dist/elemica-suggest.js').toString())
chai.should()

elemicaSuggestionRenderingSpec = (options, expectedMarkup, done) ->
  $containerDiv = $("<div />")

  passedAfterSuggest = options.afterSuggest
  afterSuggest = ->
    passedAfterSuggest?()

    $containerDiv.html().should.equal(expectedMarkup)
    done()

  options.afterSuggest = afterSuggest

  $input = $("<input />").elemicaSuggest options
  $containerDiv.append($input)

  $input.val('bacon').trigger('keyup')

describe 'Suggest', ->
  it 'should extend the jQuery object', ->
    jQuery.fn.elemicaSuggest.should.be.a 'function'

  it 'should correctly provide markup for basic suggestions',  (done)->
    expectedMarkup = '<input autocomplete="off"><ul class="suggestions"><li class="active">suggestion 1</li><li>suggestion 2</li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    elemicaSuggestionRenderingSpec(suggestFunction: suggestFunction, expectedMarkup, done)

  it 'should correctly provide markup for image suggestions', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"awesome.gif\">suggestion 1</li><li><img src=\"bacon.gif\">suggestion 2</li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1', image: 'awesome.gif'}, {display: 'suggestion 2', value: 'suggestion 2', image: 'bacon.gif'}])

    elemicaSuggestionRenderingSpec(suggestFunction: suggestFunction, expectedMarkup, done)

  it 'should correctly provide markup for metadata suggestions', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\">suggestion 1<span class=\"metadata\">a good suggestion</span></li><li>suggestion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1', metadata: 'a good suggestion'}, {display: 'suggestion 2', value: 'suggestion 2', metadata: 'a great suggestion'}])

    elemicaSuggestionRenderingSpec(suggestFunction: suggestFunction, expectedMarkup, done)

  it 'should mark matches when a marker RegExp builder is provided', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"zztop.gif\">su<span class="match">gges</span>ti<span class="match">on </span>1<span class=\"metadata\">a good suggestion</span></li><li><img src=\"walnut.jpg\">su<span class="match">gges</span>ti<span class="match">on </span>2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([
        {display: 'suggestion 1', value: 'suggestion 1', image: 'zztop.gif', metadata: 'a good suggestion'},
        {display: 'suggestion 2', value: 'suggestion 2', image: 'walnut.jpg', metadata: 'a great suggestion'}
      ])
    markerRegExpFunction = (searchTerm) ->
      searchTerm.should.equal('bacon')
      /(gges|on )/g

    elemicaSuggestionRenderingSpec(
      suggestFunction: suggestFunction,
      buildMarkerRegExp: markerRegExpFunction,
      expectedMarkup,
      done
    )

  it 'should mark matches correctly when a non-global marker RegExp is provided', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"zztop.gif\">su<span class="match">gges</span>tion 1<span class=\"metadata\">a good suggestion</span></li><li><img src=\"walnut.jpg\">su<span class="match">gges</span>tion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([
        {display: 'suggestion 1', value: 'suggestion 1', image: 'zztop.gif', metadata: 'a good suggestion'},
        {display: 'suggestion 2', value: 'suggestion 2', image: 'walnut.jpg', metadata: 'a great suggestion'}
      ])
    markerRegExpFunction = (searchTerm) ->
      searchTerm.should.equal('bacon')
      /(gges|on )/

    elemicaSuggestionRenderingSpec(
      suggestFunction: suggestFunction,
      buildMarkerRegExp: markerRegExpFunction,
      expectedMarkup,
      done
    )

  it 'should abort match marking when an empty match occurs', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"zztop.gif\">suggestion 1<span class=\"metadata\">a good suggestion</span></li><li><img src=\"walnut.jpg\">suggestion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([
        {display: 'suggestion 1', value: 'suggestion 1', image: 'zztop.gif', metadata: 'a good suggestion'},
        {display: 'suggestion 2', value: 'suggestion 2', image: 'walnut.jpg', metadata: 'a great suggestion'}
      ])
    markerRegExpFunction = (searchTerm) ->
      searchTerm.should.equal('bacon')
      /(gges|)/

    elemicaSuggestionRenderingSpec(
      suggestFunction: suggestFunction,
      buildMarkerRegExp: markerRegExpFunction,
      expectedMarkup,
      done
    )


  it 'should correctly provide markup for suggestions with all options', (done) ->
    expectedMarkup = '<input autocomplete=\"off\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"zztop.gif\">suggestion 1<span class=\"metadata\">a good suggestion</span></li><li><img src=\"walnut.jpg\">suggestion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([
        {display: 'suggestion 1', value: 'suggestion 1', image: 'zztop.gif', metadata: 'a good suggestion'},
        {display: 'suggestion 2', value: 'suggestion 2', image: 'walnut.jpg', metadata: 'a great suggestion'}
      ])

    elemicaSuggestionRenderingSpec(suggestFunction: suggestFunction, expectedMarkup, done)

  it 'should invoke afterSelect with the selected suggestion after a selection is made', (done) ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    $input = $("<input />").elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: (suggestion) ->
        suggestion.display.should.equal("suggestion 1")
        suggestion.value.should.equal("suggestion 1")
        done()

    $containerDiv = $("<div />").append($input)
    $input.val('bacon').trigger('keyup')

    $containerDiv.find(".suggestions .active").trigger('element-selected')

  it 'should render suggestion after paste a value', (done) ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    $input = $("<input />").elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: (suggestion) ->
        suggestion.display.should.equal("suggestion 1")
        suggestion.value.should.equal("suggestion 1")
        done()

    $containerDiv = $("<div />").append($input)
    # simulate user CMD+C
    window.clipboardData.setData('Text', 'bacon')
    $input.trigger('paste')

    $containerDiv.find(".suggestions .active").trigger('element-selected')

  it 'should invoke afterSelect with the selected suggestion after an identical selection is made', (done) ->
    firstSuggestion = undefined
    invocationCount = 0
    $input = $("<input />")
    $containerDiv = $("<div />").append($input)

    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    makeASelection = ->
      $input.val('bacon').trigger('keyup')
      $containerDiv.find(".suggestions .active").trigger('element-selected')

    $input.elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: (suggestion) ->
        invocationCount++

        if invocationCount == 1
          firstSuggestion = suggestion
          makeASelection()
        else
          suggestion.display.should.equal(firstSuggestion.display)
          suggestion.value.should.equal(firstSuggestion.value)
          done()

    makeASelection()

  # This spec is marked as pending because jsdom doesn't properly support the layout calculations
  # that are required to do some of the checks to make this test work. To resolve that we're going
  # to rewrite these tests at some point to use Phantom.js. For now, we'll leave this as pending so
  # we come back to it.
  it 'should invoke afterSelect with the selected suggestion if the suggestion was manually entered'

  it 'should invoke afterSelect with null after a selection is cleared', (done) ->
    invocationCount = 0
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: (suggestion) ->
        invocationCount++

        if invocationCount == 2
          # chai existence testing appears to be broken...
          assert.equal(suggestion, null)
          done()
        else
          keydownEvent = $.Event 'keydown'
          keydownEvent.which = 8
          $input.trigger keydownEvent

    $containerDiv = $("<div />").append($input)
    $input.val('bacon').trigger('keyup')
    $containerDiv.find(".suggestions .active").trigger('element-selected')

  it 'should invoke noSuggestionMatched callback if no valid selection was made', (done) ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'bacon', value: 'bacon'}])
          
    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      noSuggestionMatched: (value) -> 
        value.should.equal('lol')
        done()
          
    $input.val('lol').trigger('keyup')
    $input.trigger('blur')
    
  it 'should not invoke noSuggestionMatched callback if valid selection was made', ->
    invocationCount = 0
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'bacon', value: 'bacon'}])

    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      noSuggestionMatched: -> invocationCount++

    $containerDiv = $("<div />").append($input)
    $input.val('bacon').trigger('keyup')
    $containerDiv.find(".suggestions .active").trigger('element-selected')

    invocationCount.should.equal(0)

  it 'should clear typeahead input by default when no valid selection was made', ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])
    
    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
    
    $input.val('bacon').trigger('keyup')
    $input.val().should.equal('bacon')
    
    $input.trigger('blur')
    $input.val().should.equal('')
    
  it 'should not clear typehead input when no valid selection was made and noSuggestionMatched returned falsey', ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])      
        
    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      noSuggestionMatched: -> false
        
    $input.val('bacon').trigger('keyup')
    $input.val().should.equal('bacon')
    
    $input.trigger('blur')
    $input.val().should.equal('bacon')
    
  it 'should not invoke afterSelect when no valid selection was made and noSuggestionMatched returned falsey', ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      noSuggestionMatched: -> false
      afterSelect: -> throw new Error('afterSelect should not be run if noSuggestionMatched return falsey')

    $input.val('bacon').trigger('keyup')
    $input.trigger('blur')

  it 'should not invoke afterSelect if user entered nothing', ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])
      
    $input = $("<input />")
    $input.elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: -> throw new Error('afterSelect should not be run if user entered nothing')
      
    $input.trigger('blur')

describe 'Suggest when handling keyboard shortcuts', ->
  onSelect = () ->
  onSuggest = () ->

  suggestFunction = (searchTerm, populateFn) ->
    populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

  $input = $("<input />")
  $input.elemicaSuggest
    suggestFunction: suggestFunction
    afterSelect: (selection) -> onSelect?(selection)
    afterSuggest: () -> onSuggest?()

  $containerDiv = $("<div />").append($input)

  $input.val('bacon').trigger('keyup') # show the completion dropdown

  triggerKeyUp = ($input, keyCode, ctrlKey) ->
    keyupEvent = $.Event 'keyup'
    keyupEvent.which = keyCode
    keyupEvent.ctrlKey = ctrlKey || false

    $input.trigger keyupEvent

  # The following tests assume they run in order as they move through the
  # suggestion list.
  it 'should move the selection down if the down arrow is pressed', ->
    triggerKeyUp $input, 40

    $containerDiv.find(".suggestions .active").text().should.equal('suggestion 2')

  it 'should move the selection up if the up arrow is pressed', ->
    triggerKeyUp $input, 38

    $containerDiv.find(".suggestions .active").text().should.equal('suggestion 1')

  it 'should move the selection down if C-N is pressed', ->
    triggerKeyUp $input, 78, true

    $containerDiv.find(".suggestions .active").text().should.equal('suggestion 2')

  it 'should move the selection up if C-P is pressed', ->
    triggerKeyUp $input, 80, true

    $containerDiv.find(".suggestions .active").text().should.equal('suggestion 1')

  it 'should select the highlighted item if enter is pressed', ->
    onSelect = (selected) ->
      selected.display.should.equal('suggestion 1')
      selected.value.should.equal('suggestion 1')

    triggerKeyUp $input, 13, true

    $containerDiv.find(".suggestions").length.should.equal(0)

  it 'should not trigger a search on keyups for non-printable characters', ->
    searchCalls = 0
    onSuggest = -> searchCalls += 1

    triggerKeyUp $input, 9
    triggerKeyUp $input, 13
    triggerKeyUp $input, 16
    triggerKeyUp $input, 17
    triggerKeyUp $input, 18
    triggerKeyUp $input, 37
    triggerKeyUp $input, 39
    triggerKeyUp $input, 91
    triggerKeyUp $input, 92

    searchCalls.should.equal(0)

  it 'should trigger a search on keyups for non-printable characters', ->
    searchCalls = 0
    onSuggest = -> searchCalls += 1

    triggerKeyUp $input, 25

    searchCalls.should.equal(1)
