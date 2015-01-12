Marionette = require('backbone.marionette')

module.exports = class SearchListFiltersView extends Marionette.CollectionView
  tagName: 'ul'
  className: 'search-list-filters'
  childView: require('./SearchItemView')
  childViewOptions:
    showFilters: true

  initialize: ->
    throw 'Must pass options.collection, a Collection (of filter Searches)' if !@collection?

    @listenTo(@collection, 'add remove fetch reset', @_refreshFiltersExist)

  _refreshFiltersExist: ->
    @$el.toggleClass('filters-exist', @collection.length > 0)
