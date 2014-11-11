_ = require('lodash')
Backbone = require('backbone')

Comparators =
  'name-asc': (s1, s2) -> s1.attributes.name.localeCompare(s2.attributes.name)
  'name-desc': (s1, s2) -> s2.attributes.name.localeCompare(s1.attributes.name)
  'n-documents-asc': (s1, s2) ->
    if s1.attributes.nDocuments == s2.attributes.nDocuments
      s1.attributes.name.localeCompare(s2.attributes.name)
    else if !s1?
      1
    else if !s2?
      -1
    else
      s1.attributes.nDocuments - s2.attributes.nDocuments
  'n-documents-desc': (s1, s2) ->
    if s1.attributes.nDocuments == s2.attributes.nDocuments
      s1.attributes.name.localeCompare(s2.attributes.name)
    else if !s1?
      1
    else if !s2?
      -1
    else
      s2.attributes.nDocuments - s1.attributes.nDocuments

module.exports = class SearchListView extends Backbone.View
  className: 'sort sort-by-name-asc'

  template: require('../templates/SearchListHeader')

  events:
    'click a.sort-by-n-documents-desc': 'onSortByNDocumentsDesc'
    'click a.sort-by-n-documents-asc': 'onSortByNDocumentsAsc'
    'click a.sort-by-name-asc': 'onSortByNameAsc'
    'click a.sort-by-name-desc': 'onSortByNameDesc'

  initialize: ->
    throw 'Must pass options.collection, a Collection' if !@collection?

    @listenTo(@collection, 'change:nDocuments', @onNDocumentsChanged)
    @listenTo(@collection, 'change:name', @onNameChanged)
    @listenTo(@collection, 'add remove reset', @refreshNSearches)

    @doSort = _.throttle(@collection.sort.bind(@collection), 500)

    @refreshNSearches()
    @render()

  render: ->
    @$el.html(@template())

  refreshNSearches: ->
    @$el.attr('data-n-searches', @collection.length)

  onNDocumentsChanged: ->
    @doSort() if @sortKey == 'n-documents-asc' || @sortKey == 'n-documents-desc'

  onNameChanged: ->
    @doSort()

  sortBy: (key) ->
    @sortKey = key
    @$el.attr('class', "sort sort-by-#{key}")
    @collection.comparator = Comparators[@sortKey]
    @doSort()

  onSortByNameAsc: (e) ->
    e.preventDefault()
    @sortBy('name-asc')

  onSortByNameDesc: (e) ->
    e.preventDefault()
    @sortBy('name-desc')

  onSortByNDocumentsDesc: (e) ->
    e.preventDefault()
    @sortBy('n-documents-desc')

  onSortByNDocumentsAsc: (e) ->
    e.preventDefault()
    @sortBy('n-documents-asc')
