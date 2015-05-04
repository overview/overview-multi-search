Marionette = require('backbone.marionette')

module.exports = class SearchListView extends Marionette.CollectionView
  tagName: 'ul'
  className: 'searches'
  childView: require('./SearchItemView')
