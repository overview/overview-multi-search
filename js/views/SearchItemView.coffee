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
      @model.save { query: query, nDocuments: null, error: null },
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
    @el.className = "search #{status}"

  _refreshIsFilter: ->
    hasFilterPosition = @model.get('filterPosition')?
    return if hasFilterPosition == @_hasFilterPosition
    @_hasFilterPosition = hasFilterPosition

    if hasFilterPosition
      @$el.addClass('filter')
      @_animateDisappear() if @$el.parent().hasClass('searches')
    else
      @$el.removeClass('filter')
      @_animateAppear() if @$el.parent().hasClass('searches')

  _animateDisappear: ->
    @_css =
      paddingTop: parseInt(@$el.css('padding-top'), 10)
      paddingBottom: parseInt(@$el.css('padding-bottom'), 10)
      height: parseInt(@$el.css('height'), 10)

    $clone = @$el.clone()
      .addClass('animation-clone')
      .css
        position: 'absolute'
        background: 'white'
        top: @$el.position().top + 'px'
        left: @$el.position().left + 'px'
        height: @_css.height + 'px'
        width: '100%'
        opacity: 1
      .insertAfter(@$el)

    @$el
      .stop(true)
      .css(opacity: 0, overflow: 'hidden', height: @_css.height + 'px')
      .animate(height: 0, paddingTop: 0, paddingBottom: 0)

    $clone
      .animate
        marginTop: -2 * (@_css.height + @_css.paddingTop + @_css.paddingBottom) + 'px'
        opacity: 0
      .queue(-> $clone.remove())

  _animateAppear: ->
    if !@_css?
      @$el
        .stop(true)
        .css
          height: 'auto'
          paddingBottom: '.25em'
          paddingTop: '.25em'
          opacity: 1
          overflow: 'visible'
    else
      # Ensure @$el.queue() happens before or on same tick as $clone.remove()
      
      @$el
        .stop(true)
        .animate
          height: @_css.height + 'px'
          paddingBottom: @_css.paddingBottom + 'px'
          paddingTop: @_css.paddingTop + 'px'
        .queue(=> @$el.css(opacity: 1, overflow: 'visible', height: 'auto'))

      $clone = @$el.clone()
        .addClass('animation-clone')
        .css
          position: 'absolute'
          width: '100%'
          top: @$el.position().top + 'px'
          left: @$el.position().left + 'px'
          marginTop: -2 * (@_css.height + @_css.paddingTop + @_css.paddingBottom) + 'px'
          zIndex: 1
          height: @_css.height + 'px'
          paddingTop: @_css.paddingTop + 'px'
          paddingBottom: @_css.paddingBottom + 'px'
        .insertAfter(@$el)
        .animate
          marginTop: 0
          opacity: 1
        .queue(-> $clone.remove())
