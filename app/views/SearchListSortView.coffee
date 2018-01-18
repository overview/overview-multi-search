Backbone = require('backbone')

module.exports = class SearchListSortView extends Backbone.View
  className: 'search-list-sort'
  template: require('../templates/SearchListSort')

  events:
    'click a.sort-by-n-documents-desc': '_onSortByNDocumentsDesc'
    'click a.sort-by-n-documents-asc': '_onSortByNDocumentsAsc'
    'click a.sort-by-query-asc': '_onSortByQueryAsc'
    'click a.sort-by-query-desc': '_onSortByQueryDesc'

  initialize: ->
    throw 'Must pass model, a SearchList' if !@model?.searches?

    @listenTo(@model, 'change:sortKey', @_refreshSortKey)
    @listenTo(@model.searches, 'add remove fetch reset', @_refreshNSearches)

    @render()

  render: ->
    @$el.html(@template())
    @_refreshSortKey()
    @_refreshNSearches()
    @

  _refreshSortKey: ->
    @$el.attr('class', "search-list-sort sort-by-#{@model.get('sortKey')}")

  _refreshNSearches: ->
    @$el.attr('data-n-searches', @model.searches.length)

  _sortBy: (key) ->
    @model.setSortKey(key)

  _onSortByQueryAsc: (e) ->
    e.preventDefault()
    @_sortBy('query-asc')

  _onSortByQueryDesc: (e) ->
    e.preventDefault()
    @_sortBy('query-desc')

  _onSortByNDocumentsDesc: (e) ->
    e.preventDefault()
    @_sortBy('n-documents-desc')

  _onSortByNDocumentsAsc: (e) ->
    e.preventDefault()
    @_sortBy('n-documents-asc')
