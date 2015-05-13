Backbone = require('backbone')
SearchList = require('./models/SearchList')
SearchListFiltersFooterView = require('./views/SearchListFiltersFooterView')
SearchListFiltersHeaderView = require('./views/SearchListFiltersHeaderView')
SearchListFiltersView = require('./views/SearchListFiltersView')
SearchListSortView = require('./views/SearchListSortView')
SearchListView = require('./views/SearchListView')
SearchFormView = require('./views/SearchFormView')
SourceView = require('./views/SourceView')

module.exports = class App extends Backbone.View
  template: require('./templates/app')

  events:
    'click a.edit-source': 'onEditSource'

  initialize: (options) ->
    throw 'Must pass options.searches, a Searches Collection' if !options.searches
    @searches = options.searches
    @searchList = new SearchList({}, searches: @searches)

    @searches.on('add change:query change:filter', (s) -> s.refreshIfNeeded())
    @searches.each((s) -> s.refreshIfNeeded())
    @children = {}

  clearChildren: ->
    c.remove() for __, c of @children
    @children = {}

  render: ->
    @clearChildren()
    @$el.html(@template())

    ui =
      filterList: @$('.filter-list')
      searchList: @$('.search-list')
      searchForm: @$('.search-form')

    @children =
      searchListFiltersHeader: new SearchListFiltersHeaderView(collection: @searchList.filters)
      searchListFiltersFooter: new SearchListFiltersFooterView(collection: @searchList.filters)
      searchListFilters: new SearchListFiltersView(collection: @searchList.filters)
      searchListSort: new SearchListSortView(model: @searchList)
      searchList: new SearchListView(collection: @searches)
      searchForm: new SearchFormView

    for k, view of @children
      view.render()

    ui.filterList.append(@children.searchListFiltersHeader.el)
    ui.filterList.append(@children.searchListFilters.el)
    ui.filterList.append(@children.searchListFiltersFooter.el)
    ui.searchList.append(@children.searchListSort.el)
    ui.searchList.append(@children.searchList.el)
    ui.searchForm.append(@children.searchForm.el)

    @listenTo(@children.searchForm, 'create', @onCreate)
    @listenTo(@children.searchList, 'childview:add-filter', @_onAddFilter)
    @listenTo(@children.searchList, 'childview:select', @_onSelect)
    @listenTo(@children.searchListFilters, 'childview:select', @_onSelect)
    @listenTo(@children.searchListFilters, 'childview:remove-filter', @_onRemoveFilter)
    @

  onCreate: (attributes) ->
    model = @searches.create(attributes)
    model.refresh()
    @select(model)

  onEditSource: (e) ->
    e.preventDefault()

    sourceView = new SourceView(collection: @searches)
    @listenTo(sourceView, 'done', -> sourceView.remove())
    sourceView.render()
    @$el.append(sourceView.el)

  select: (search) ->
    query = search.getFullQuery()
    window.parent.postMessage({
      call: 'setDocumentListParams'
      args: [ { q: query } ]
    }, global.server)

    @searches.forEach((model) -> model.set(selected: model == search))

  _onAddFilter: (view, search) -> @searchList.addFilter(search)
  _onRemoveFilter: (view, search) -> @searchList.removeFilter(search)
  _onSelect: (view, search) -> @select(search)
