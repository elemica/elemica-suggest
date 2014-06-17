chai = require 'chai'
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

  $input.val('bacon').trigger('keyup', {keyCode: 99})

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

  it 'should correctly invoke afterSelect after a selection is made by the user', (done) ->
    suggestFunction = (searchTerm, populateFn) ->
      populateFn([{display: 'suggestion 1', value: 'suggestion 1'}, {display: 'suggestion 2', value: 'suggestion 2'}])

    $input = $("<input />").elemicaSuggest
      suggestFunction: suggestFunction
      afterSelect: (suggestion) ->
        suggestion.display.should.equal("suggestion 1")
        suggestion.value.should.equal("suggestion 1")
        done()

    $containerDiv = $("<div />").append($input)
    $input.val('bacon').trigger('keyup', {keyCode: 99})

    $containerDiv.find(".suggestions .active").trigger('element-selected')

