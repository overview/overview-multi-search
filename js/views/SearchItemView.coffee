Marionette = require('backbone.marionette')

module.exports = class SearchItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'search'

  events:
    'click .delete': 'onDelete'
    'click a.object': 'onClick'

  modelEvents:
    change: 'render'

  onClick: (e) ->
    e.preventDefault()
    attrs = @model.attributes
    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { q: encodeURIComponent(attrs.query), name: attrs.name } ]
    }, global.server)

  template: require('../templates/SearchItem')

  serializeData: -> @model.attributes

  onDelete: (e) ->
    e.preventDefault()

    if window.confirm('Are you sure you want to delete this search?')
      @model.destroy()
