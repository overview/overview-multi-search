Backbone = require('backbone')
SearchListView = require('./views/SearchListView')
SearchListHeaderView = require('./views/SearchListHeaderView')
SearchFormView = require('./views/SearchFormView')
SourceView = require('./views/SourceView')

module.exports = class App extends Backbone.View
  template: require('./templates/app')

  events:
    'click a.edit-source': 'onEditSource'

  initialize: (options) ->
    throw 'Must pass options.searches, a Searches Collection' if !options.searches
    @searches = options.searches
    @children = {}

  clearChildren: ->
    c.remove() for __, c of @children
    @children = {}

  render: ->
    @clearChildren()
    @$el.html(@template())
    @ui =
      searchListHeader: @$('.search-list-header')
      searchList: @$('.search-list')
      searchForm: @$('.search-form')

    @children =
      searchListHeader: new SearchListHeaderView(collection: @searches)
      searchList: new SearchListView(collection: @searches)
      searchForm: new SearchFormView

    for k, view of @children
      view.render()
      @ui[k].append(view.el)

    @listenTo(@children.searchForm, 'create', @onCreate)
    @

  onCreate: (attributes) ->
    model = @searches.create(attributes)
    model.startRefresh()

  onEditSource: (e) ->
    e.preventDefault()

    sourceView = new SourceView(collection: @searches)
    @listenTo(sourceView, 'done', -> sourceView.remove())
    sourceView.render()
    @$el.append(sourceView.el)
