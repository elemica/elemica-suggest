chai = require 'chai'
jsdom = require 'jsdom'
jQuery = require('jquery')(jsdom.jsdom().createWindow())
fs = require 'fs'

eval(fs.readFileSync('dist/elemica-suggest.js').toString())
chai.should()

describe 'Suggest', ->
  it 'should extend the jQuery object', ->
    jQuery.fn.elemicaSuggest.should.be.a 'function'

  it 'should correctly provide markup for basic suggestions'

  it 'should correctly provide markup for image suggestions'

  it 'should correctly provide markup for metadata suggestions'

  it 'should correctly provide markup for suggestions with all options'

