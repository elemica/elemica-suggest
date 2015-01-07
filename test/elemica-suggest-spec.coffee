chai = require 'chai'
assert = require("assert")
jsdom = require 'jsdom'
jQuery = require('jquery')(jsdom.jsdom().createWindow())
$ = jQuery
fs = require 'fs'

eval(fs.readFileSync('dist/elemica-suggest.js').toString())
chai.should()

elemicaSuggestionRenderingSpec = (suggestFunction, expectedMarkup, done) ->
  $containerDiv = $("<div />")

  afterSuggest = ->
    $containerDiv.html().should.equal(expectedMarkup)
    done()

  $input = $("<input />").elemicaSuggest
    suggestFunction: suggestFunction,
    afterSuggest: afterSuggest
  $containerDiv.append($input)

  $input.val('bacon').trigger('keyup')

describe 'Suggest', ->
  it 'should extend the jQuery object', ->
    jQuery.fn.elemicaSuggest.should.be.a 'function'

  it 'should correctly provide markup for basic suggestions',  (done)->
    expectedMarkup = '<input autocomplete="off" value="bacon"><ul class="suggestions"><li class="active">suggestion 1</li><li>suggestion 2</li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    elemicaSuggestionRenderingSpec(suggestFunction, expectedMarkup, done)

  it 'should correctly provide markup for image suggestions', (done) ->
    expectedMarkup = '<input autocomplete=\"off\" value=\"bacon\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"awesome.gif\">suggestion 1</li><li><img src=\"bacon.gif\">suggestion 2</li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1', image: 'awesome.gif'}, {display: 'suggestion 2', value: 'suggestion 2', image: 'bacon.gif'}])

    elemicaSuggestionRenderingSpec(suggestFunction, expectedMarkup, done)

  it 'should correctly provide markup for metadata suggestions', (done) ->
    expectedMarkup = '<input autocomplete=\"off\" value=\"bacon\"><ul class=\"suggestions\"><li class=\"active\">suggestion 1<span class=\"metadata\">a good suggestion</span></li><li>suggestion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1', metadata: 'a good suggestion'}, {display: 'suggestion 2', value: 'suggestion 2', metadata: 'a great suggestion'}])

    elemicaSuggestionRenderingSpec(suggestFunction, expectedMarkup, done)

  it 'should correctly provide markup for suggestions with all options', (done) ->
    expectedMarkup = '<input autocomplete=\"off\" value=\"bacon\"><ul class=\"suggestions\"><li class=\"active\"><img src=\"zztop.gif\">suggestion 1<span class=\"metadata\">a good suggestion</span></li><li><img src=\"walnut.jpg\">suggestion 2<span class=\"metadata\">a great suggestion</span></li></ul>'
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([
        {display: 'suggestion 1', value: 'suggestion 1', image: 'zztop.gif', metadata: 'a good suggestion'},
        {display: 'suggestion 2', value: 'suggestion 2', image: 'walnut.jpg', metadata: 'a great suggestion'}
      ])

    elemicaSuggestionRenderingSpec(suggestFunction, expectedMarkup, done)

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
          keydownEvent.keyCode = 8
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
    
  it 'should not clear typehead input when no valid selection was made and noSuggestionMatched returns false', ->
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