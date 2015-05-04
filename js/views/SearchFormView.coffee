Backbone = require('backbone')

module.exports = class SearchFormView extends Backbone.View
  className: 'new-search'

  template: require('../templates/SearchForm')

  events:
    'submit form': 'onSubmit'

  render: ->
    @$el.html(@template())

  onSubmit: (e) ->
    e.preventDefault()

    query = @$('input[name=query]').val().trim()

    if query
      @trigger('create', query: query)
      @$('form')[0].reset()
