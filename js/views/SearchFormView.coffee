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

    name = @$('input[name=name]').val().trim()

    if name
      query = name
      @trigger('create', name: name, query: name)
      @$('form')[0].reset()
