Backbone = require('backbone')

module.exports = class Searches extends Backbone.Collection
  model: require('../models/Search')
  url: -> "#{@server}/api/v1/store/objects"

  initialize: (models, options) ->
    throw 'Must pass options.documentSetId' if !options.documentSetId
    throw 'Must pass options.server, a URL' if !options.server

    @documentSetId = options.documentSetId
    @server = options.server
