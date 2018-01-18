Backbone = require('backbone')

module.exports = class SearchListFiltersHeaderView extends Backbone.View
  tagName: 'h2'
  className: 'search-list-filters-header'

  initialize: ->
    throw 'Must pass options.collection, a Collection (of filter Searches)' if !@collection?

    @listenTo(@collection, 'add remove fetch reset', @render)

  render: ->
    if @collection.length > 0
      if @collection.length == 1
        @$el.text('Filter')
      else
        @$el.text('Filters')
        
    @$el.toggleClass('filters-exist', @collection.length > 0)
