Backbone = require('backbone')
SearchListView = require('./views/SearchListView')
SearchFormView = require('./views/SearchFormView')
VizView = require('./views/VizView')

module.exports = class App extends Backbone.View
  template: require('./templates/app')

  initialize: (options) ->
    throw 'Must pass options.searches, a Searches Collection' if !options.searches
    throw 'Must pass options.documentSetId, a Number' if !options.documentSetId
    @documentSetId = options.documentSetId
    @searches = options.searches
    @children = {}

  clearChildren: ->
    c.remove() for __, c of @children
    @children = {}

  render: ->
    @clearChildren()
    @$el.html(@template())
    @ui =
      searchList: @$('.search-list')
      searchForm: @$('.search-form')
      documentList: @$('.document-list')

    @children =
      searchList: new SearchListView(collection: @searches)
      searchForm: new SearchFormView(documentSetId: @documentSetId)

    for k, view of @children
      view.render()
      @ui[k].append(view.el)

    @listenTo(@children.searchForm, 'create', @onCreate)
    @

  onCreate: (attributes) ->
    @searches.create(attributes)
