Backbone = require('backbone')

module.exports = class SearchListFiltersHeaderView extends Backbone.View
  tag: 'h3'
  className: 'search-list-filters-header'

  initialize: ->
    throw 'Must pass options.collection, a Collection (of filter Searches)' if !@collection?

    @listenTo(@collection, 'add remove fetch reset', @render)

  render: ->
    if @collection.length > 0
      if @collection.length == 1
        @$el.text("The searches below only count the documents the above search found.")
      else
        @$el.text("The searches below only count the documents the above searches found.")
        
    @$el.toggleClass('filters-exist', @collection.length > 0)
