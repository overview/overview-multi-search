Marionette = require('backbone.marionette')

module.exports = class SearchListFiltersView extends Marionette.CollectionView
  tagName: 'ul'
  className: 'search-list-filters'
  childView: require('./SearchItemView')
  childViewOptions:
    showFilters: true
