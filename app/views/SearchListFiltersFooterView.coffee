Backbone = require('backbone')

module.exports = class SearchListFiltersFooterView extends Backbone.View
  tagName: 'p'
  className: 'search-list-filters-footer'

  initialize: ->
    throw 'Must pass options.collection, a Collection (of filter Searches)' if !@collection?

    @listenTo(@collection, 'add remove fetch reset', @render)

  render: ->
    if @collection.length > 0
      if @collection.length == 1
        @$el.text('This filter applies to all searches below.')
      else
        @$el.text('These filters apply to all searches below.')

    @$el.toggleClass('filters-exist', @collection.length > 0)
