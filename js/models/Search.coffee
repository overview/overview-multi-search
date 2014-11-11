_ = require('lodash')
Backbone = require('backbone')

# An search. Has a name and some terms.
module.exports = class Search extends Backbone.Model
  defaults:
    name: ''
    query: ''
    nDocuments: null
    error: null

  parse: (json) -> _.extend({ id: json.id }, json.json)
  toJSON: -> { json: _.omit(@attributes, 'id') }

  startRefresh: ->
    server = @collection.server
    documentSetId = @collection.documentSetId
    query = @get('query')

    url = "#{server}/api/v1/document-sets/#{documentSetId}/documents?fields=id&q=#{encodeURIComponent(query)}"

    Backbone.ajax
      url: url
      success: (ids) =>
        @save(nDocuments: ids.length, error: null)
      error: (xhr) =>
        @save(nDocuments: null, error: xhr.responseJSON)
