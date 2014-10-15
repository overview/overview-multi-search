_ = require('lodash')
Backbone = require('backbone')

module.exports = class Searches extends Backbone.Collection
  comparator: 'name'
  model: require('../models/Search')
  url: -> "#{@server}/api/v1/vizs/#{@vizId}/objects"

  initialize: (models, options) ->
    throw 'Must pass options.vizId' if !options.vizId
    throw 'Must pass options.documentSetId' if !options.documentSetId
    throw 'Must pass options.server, a URL' if !options.server

    @documentSetId = options.documentSetId
    @vizId = options.vizId
    @server = options.server
