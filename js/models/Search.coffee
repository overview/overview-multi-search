_ = require('lodash')
Backbone = require('backbone')

# An search. Has a name and some terms.
module.exports = class Search extends Backbone.Model
  defaults:
    name: ''
    query: ''
    nDocuments: null
    error: null
    filter: null
    filterNDocuments: null
    filterError: null

  parse: (json) -> _.extend({ id: json.id }, json.json)
  toJSON: -> { json: _.pick(@attributes, 'name', 'query', 'nDocuments', 'error') }

  ###
  Sets the query, if it changed.
  ###
  setQuery: (query) ->
    if query != @get('query')
      @set
        query: query
        error: null
        nDocuments: null

  ###
  Sets the filter, if it changed.
  ###
  setFilter: (filter) ->
    if filter != @get('filter')
      @set
        filter: filter
        filterError: null
        filterNDocuments: null

  ###
  Returns the query including filter, if applicable
  ###
  getFullQuery: ->
    if @get('filter')
      "#{@get('filter')} AND (#{@get('query')})"
    else
      query

  ###
  Tries to get a number of documents from the server.

  When `filter` is non-`null`, will asynchronously set `filterNDocuments` and
  `filterError`. When `filter` is `null`, will asynchronously set `nDocuments`
  and `error`.

  If `query` or `filter` changes before the server responds, the obsolete
  response will be ignored.

  @param query [String] `attributes.query` when this method was called.
  @param filter [String,null] `attributes.filter` when this method was called.
  ###
  _doRefresh: (query, filter) ->
    server = @collection.server
    documentSetId = @collection.documentSetId

    q = if filter
      "#{filter} AND (#{query})"
    else
      query

    url = "#{server}/api/v1/document-sets/#{documentSetId}/documents?fields=id&q=#{encodeURIComponent(q)}"

    responseIsStale = =>
      query != @get('query') || filter != @get('filter')

    Backbone.ajax
      url: url
      success: (ids) =>
        return if responseIsStale()
        if filter
          @set(filterNDocuments: ids.length, filterError: null)
        else
          @set(nDocuments: ids.length, error: null)
        @save()
      error: (xhr) =>
        return if responseIsStale()
        if filter
          @set(filterNDocuments: null, filterError: xhr.responseJSON)
        else
          @set(nDocuments: null, error: xhr.responseJSON)
        @save()

  ###
  Searches against the server, to find `nDocuments` or `filterNDocuments`.

  This will call `@save()`, whether the call succeeds or errors.

  On error, `filterError` or `error` will be set.
  ###
  refresh: ->
    @_doRefresh(@get('query'), @get('filter'))

  ###
  Calls `@refresh()` if we're missing `nDocuments or `filterNDocuments`.

  Call this:

  * after `setQuery()`
  * after `setFilter()`
  * when the user asks for it: say, if `error != null`
  * on first load from the server
  ###
  refreshIfNeeded: ->
    if @get('filter')
      if !@get('filterNDocuments')?
        @refresh()
    else
      if !@get('nDocuments')?
        @refresh()
