$ = require('jquery')
Marionette = require('backbone.marionette')

module.exports = class SearchItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'search'

  events:
    'click .delete': 'onDelete'
    'click .edit': 'onEdit'
    'click .toggle-filter': 'onToggleFilter'
    'click a.object': 'onClick'
    'submit form': 'onSubmit'
    'reset form': 'onReset'

  modelEvents:
    change: 'render'

  ui:
    name: 'input[name=name]'
    query: 'input[name=query]'

  initialize: ->
    @listenTo(@model, 'filterPosition', @_onFilterPositionChanged)

  onClick: (e) ->
    e.preventDefault()
    query = @model.getFullQuery()
    name = @model.get('name')
    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { q: query, name: "in search “#{name}”" } ]
    }, global.server)

  setEditing: (editing) -> @$el.toggleClass('editing', editing)

  onEdit: (e) -> @setEditing(true)

  onSubmit: (e) ->
    e.preventDefault()
    name = @ui.name.val().trim()
    query = @ui.query.val().trim()
    if name && query
      @model.save { name: name, query: query, nDocuments: null, error: null },
        success: (model) -> model.refreshIfNeeded()
    @setEditing(false)

  onReset: (e) ->
    # do not e.preventDefault() -- we want to reset the form
    @setEditing(false)

  template: require('../templates/SearchItem')

  serializeData: ->
    attrs = @model.attributes

    always =
      id: attrs.id
      query: attrs['query']
      name: attrs['name']

    depending = if attrs['filter']?
      nDocuments: attrs['filterNDocuments']
      error: attrs['error']
    else
      nDocuments: attrs['nDocuments']
      error: attrs['error']

    $.extend(always, depending)

  onDelete: (e) ->
    e.preventDefault()

    if window.confirm('Are you sure you want to delete this search?')
      @model.destroy()

  onRender: -> @_refreshIsFilter()

  onToggleFilter: (e) ->
    e.preventDefault()
    if !@model.get('filterPosition')?
      @trigger('add-filter', @model)
    else
      @trigger('remove-filter', @model)

  _onFilterPositionChanged: -> @_refreshIsFilter()

  _refreshIsFilter: ->
    @$el.toggleClass('filter', @model.get('filterPosition')?)
