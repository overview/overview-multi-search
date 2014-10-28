$ = require('jquery')
Marionette = require('backbone.marionette')

module.exports = class SearchItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'search'

  events:
    'click .delete': 'onDelete'
    'click .edit': 'onEdit'
    'click a.object': 'onClick'
    'submit form': 'onSubmit'
    'reset form': 'onReset'

  modelEvents:
    change: 'render'

  ui:
    name: 'input[name=name]'
    query: 'input[name=query]'

  onClick: (e) ->
    e.preventDefault()
    attrs = @model.attributes
    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { q: attrs.query, name: attrs.name } ]
    }, global.server)

  setEditing: (editing) -> @$el.toggleClass('editing', editing)

  onEdit: (e) -> @setEditing(true)

  onSubmit: (e) ->
    e.preventDefault()
    name = @ui.name.val().trim()
    query = @ui.query.val().trim()
    if name && query
      @model.save { name: name, query: query, nDocuments: null, error: null },
        success: (model) -> model.startRefresh()
    @setEditing(false)

  onReset: (e) ->
    # do not e.preventDefault() -- we want to reset the form
    @setEditing(false)

  template: require('../templates/SearchItem')

  serializeData: -> @model.attributes

  onDelete: (e) ->
    e.preventDefault()

    if window.confirm('Are you sure you want to delete this search?')
      @model.destroy()
