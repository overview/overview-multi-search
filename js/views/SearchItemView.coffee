$ = require('jquery')
Marionette = require('backbone.marionette')

module.exports = class SearchItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'search'

  events:
    'click .delete': 'onDelete'
    'click a.object': 'onClick'
    'click .in-place-edit.name a.edit': 'onEditName'
    'click .in-place-edit.query a.edit': 'onEditQuery'
    'submit form.edit-search-name': 'onSubmitName'
    'reset form.edit-search-name': 'onResetName'
    'submit form.edit-search-query': 'onSubmitQuery'
    'reset form.edit-search-query': 'onResetQuery'

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
      args: [ { q: encodeURIComponent(attrs.query), name: attrs.name } ]
    }, global.server)

  onEditName: (e) ->
    e.preventDefault()
    $(e.target).closest('.in-place-edit').addClass('editing')

  onEditQuery: (e) ->
    e.preventDefault()
    $(e.target).closest('.in-place-edit').addClass('editing')

  onSubmitName: (e) ->
    e.preventDefault()
    name = @ui.name.val()
    if name
      @model.save(name: name)
    $(e.target).closest('.in-place-edit').removeClass('editing')

  onSubmitQuery: (e) ->
    e.preventDefault()
    query = @ui.query.val()
    if query
      @model.save { query: query, nDocuments: null, error: null },
        success: (model) -> model.startRefresh()
    $(e.target).closest('.in-place-edit').removeClass('editing')

  onResetName: (e) -> $(e.target).closest('.in-place-edit').removeClass('editing')
  onResetQuery: (e) -> $(e.target).closest('.in-place-edit').removeClass('editing')

  template: require('../templates/SearchItem')

  serializeData: -> @model.attributes

  onDelete: (e) ->
    e.preventDefault()

    if window.confirm('Are you sure you want to delete this search?')
      @model.destroy()
