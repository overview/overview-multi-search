Backbone = require('backbone')

module.exports = class SearchFormView extends Backbone.View
  className: 'new-search'

  template: require('../templates/SearchForm')

  events:
    'submit form': 'onSubmit'

  render: ->
    @$el.html(@template())
    @ui =
      form: @$('form')
      query: @$('input[name=query]')

  onSubmit: (e) ->
    e.preventDefault()

    query = @ui.query.val().trim()

    if query
      @trigger('create', query: query)
      @ui.form[0].reset()

    @ui.query.focus()
