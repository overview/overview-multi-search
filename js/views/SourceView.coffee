assert = require('assert')
Backbone = require('backbone')
Source = require('../../lib/Source')

module.exports = class SourceView extends Backbone.View
  className: 'source'

  template: require('../templates/Source.jade')

  events:
    'submit form': 'onSubmit'
    'reset form': 'onReset'

  # Must be async -- sorry! That's the way csv.parse() is.
  render: ->
    jsons = @collection.map (item) ->
      json = item.attributes
      name: json.name
      query: json.query

    Source.withDialect('csv').stringify jsons, (err, source) =>
      assert.ifError(err)
      html = @template(source: source)
      @$el.html(html)

    @

  onSubmit: (e) ->
    e.preventDefault()

    source = @$('[name=source]').val()

    Source.withDialect('csv').parse source, (err, json) =>
      if err?
        window.alert(err.message)
      else
        toKeep = {} # cid => null
        for item in json # { name: ..., query: ... }
          item.query = item.name if 'query' not of item
          if (model = @collection.findWhere(name: item.name))
            toKeep[model.cid] = null
            if model.get('query') != item.query
              model.save(query: item.query)
              model.refreshIfNeeded()
            else
              # no changes; do nothing
          else
            model = @collection.create(item)
            model.refreshIfNeeded()
            toKeep[model.cid] = null
        for model in @collection.models.slice()
          model.destroy() if model.cid not of toKeep

        @trigger('done')

  onReset: (e) ->
    e.preventDefault()
    @trigger('done')
