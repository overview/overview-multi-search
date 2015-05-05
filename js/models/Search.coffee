_ = require('lodash')
Backbone = require('backbone')

###
Holds a query and its status.
###
module.exports = class Search extends Backbone.Model
  defaults:
    query: ''
    nDocuments: null
    error: null
    filter: null
    filterNDocuments: null
    filterError: null

  parse: (json) -> { id: json.id, query: json.json?.query }
  toJSON: -> { json: _.pick(@attributes, 'query') }

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
      @get('query')

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

    url = "#{server}/api/v1/document-sets/#{documentSetId}/documents?fields=id&q=#{encodeURIComponent(q)}&refresh=true"

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
      error: (xhr) =>
        return if responseIsStale()
        if filter
          @set(filterNDocuments: null, filterError: xhr.responseJSON)
        else
          @set(nDocuments: null, error: xhr.responseJSON)

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

  ###
  Returns { nDocuments: X, error: Y }, using `filtered` variants if applicable.

  In other words, if `filter` is set, the `nDocuments` in this result will be
  the Search's `filterNDocuments`.
  ###
  getResult: ->
    if @get('filter')
      nDocuments: @get('filterNDocuments')
      error: @get('filterError')
    else
      nDocuments: @get('nDocuments')
      error: @get('error')
