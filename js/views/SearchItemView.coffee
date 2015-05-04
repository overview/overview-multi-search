$ = require('jquery')
Marionette = require('backbone.marionette')

module.exports = class SearchItemView extends Marionette.ItemView
  tagName: 'li'
  className: 'search'

  events:
    'click .edit': 'onEdit'
    'click .delete': 'onDelete'
    'click .toggle-filter': 'onToggleFilter'
    'click .when-not-editing': 'onClick'
    'submit form': 'onSubmit'
    'reset form': 'onReset'

  modelEvents:
    change: 'render'

  ui:
    query: 'input[name=query]'

  initialize: ->
    @listenTo(@model, 'change:filterPosition', @_onFilterPositionChanged)
    @_hasFilterPosition = false

  onClick: (e) ->
    e.preventDefault()
    @trigger('select', @model)

  setEditing: (editing) -> @$el.toggleClass('editing', editing)

  onEdit: (e) ->
    e.stopPropagation()
    @setEditing(true)

  onSubmit: (e) ->
    e.preventDefault()
    query = @ui.query.val().trim()
    if query
      @model.setQuery(query)
    @setEditing(false)

  onReset: (e) ->
    # do not e.preventDefault() -- we want to reset the form
    @setEditing(false)

  template: require('../templates/SearchItem')

  serializeData: ->
    attrs = @model.attributes

    always =
      id: attrs.id
      query: attrs.query
      filterPosition: attrs.filterPosition

    result = @model.getResult()

    $.extend(always, result)

  onDelete: (e) ->
    e.preventDefault()
    e.stopPropagation()

    if window.confirm('Are you sure you want to delete this search?')
      @model.destroy()

  onRender: ->
    @_refreshStatus()
    @_refreshIsFilter()

  onToggleFilter: (e) ->
    e.preventDefault()
    e.stopPropagation()

    if !@model.get('filterPosition')?
      @trigger('add-filter', @model)
    else
      @trigger('remove-filter', @model)

  _onFilterPositionChanged: -> @_refreshIsFilter()

  _refreshStatus: ->
    result = @model.getResult()
    status = if result.nDocuments?
      'success'
    else if result.error?
      'error'
    else
      'in-progress'
    @$el.removeClass('success error in-progress')
    @$el.addClass(status)

  _refreshIsFilter: ->
    hasFilterPosition = @model.get('filterPosition')?
    return if hasFilterPosition == @_hasFilterPosition
    @_hasFilterPosition = hasFilterPosition

    if hasFilterPosition
      @$el.addClass('filter')
    else
      @$el.removeClass('filter')
