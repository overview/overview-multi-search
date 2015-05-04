assert = require('assert')
Backbone = require('backbone')

module.exports = class SourceView extends Backbone.View
  className: 'source'

  template: require('../templates/Source.jade')

  events:
    'submit form': 'onSubmit'
    'reset form': 'onReset'

  render: ->
    source = @collection.map((item) -> item.attributes.query).join('\n')
    html = @template(source: source)
    @$el.html(html)
    @ui =
      source: @$('textarea')
    @

  onSubmit: (e) ->
    e.preventDefault()

    source = @ui.source.val()
    queries = source
      .split('\n')
      .map((q) -> q.trim())
      .filter((q) -> q.length > 0)

    queriesSet = {} # query -> null
    (queriesSet[query] = null) for query in queries

    oldQueries = {} # query -> model
    (oldQueries[model.get('query')] = model) for model in @collection.models

    toRemove = (model for query, model of oldQueries when query not of queriesSet)
    toAdd = ({ query: query } for query, __ of queriesSet when query not of oldQueries)

    model.destroy() for model in toRemove
    @collection.add(toAdd)

    @trigger('done')

  onReset: (e) ->
    e.preventDefault()
    @trigger('done')
