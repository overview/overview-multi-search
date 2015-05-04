Backbone = require('backbone')
_ = require('lodash')

Comparators =
  'query-asc': (s1, s2) -> s1.attributes.query.localeCompare(s2.attributes.query)
  'query-desc': (s1, s2) -> s2.attributes.query.localeCompare(s1.attributes.query)

  'n-documents-asc': (s1, s2) ->
    n = (m) ->
      if m.attributes.filter?
        m.attributes.filterNDocuments
      else
        m.attributes.nDocuments

    n1 = n(s1)
    n2 = n(s2)

    if n1 == n2 # including both-null
      s1.attributes.query.localeCompare(s2.attributes.query)
    else if !n1?
      1
    else if !n2?
      -1
    else
      n1 - n2

  'n-documents-desc': (s1, s2) ->
    n = (m) ->
      if m.attributes.filter?
        m.attributes.filterNDocuments
      else
        m.attributes.nDocuments

    n1 = n(s1)
    n2 = n(s2)

    if n1 == n2 # including both-null
      s1.attributes.query.localeCompare(s2.attributes.query)
    else if !n1?
      1
    else if !n2?
      -1
    else
      n2 - n1

###
List of Searches, with a sort key and a filter.

The searches are stored in `@searches`. They're

There are four available sort keys: `'query-asc'`, `'query-desc'`,
`'n-documents-asc'`, and `'n-documents-desc'`. All non-"filter" searches will
be sorted accordingly.

Sorting is *lazy*: in MultiSearch, lots of document counts may change very
quickly, and there's no compelling reason to refresh the list instantaneously.

Filters are Searches that have been upgraded: they are `AND`-ed with all other
Searches. For instance, if `q1` and `q2` are Filters (in that order) and `q3`
and `q4` are regular Searches, then `q1`'s query will be `"q1"`, `q2`'s query
will be `"(q1) AND (q2)"`, `q3`'s query will be `"(q1) AND (q2) AND (q3)"`, and
`q4`'s query will be `"(q1) AND (q2) AND (q4)"`.

When displaying Searches, you'll probably want to exclude Filters and show them
elsewhere. (They'll appear in the `@searches` collection.) That's simple: each
Filter has a `filterPosition` attribute showing its position in the `@filters`
Array.
###
module.exports = class SearchList extends Backbone.Model
  defaults:
    sortKey: 'query-asc'

  initialize: (attrs, options) ->
    throw 'Must pass options.searches, a Searches' if !options.searches?
    @sortLater = options.sortLater if options.sortLater? # for unit tests

    @searches = options.searches
    @filters = new Backbone.Collection(@_findFiltersFromSearches(), {
      model: @searches.model
    })

    @_refreshComparator()

    @listenTo(@searches, 'change:query', @_onSearchQueryChanged)
    @listenTo(@searches, 'change:query change:nDocuments change:filterNDocuments reset fetch', @sortLater)
    @listenTo(@searches, 'add', @_onSearchAdded)

    @_debouncedSortLater = _.throttle(@sort.bind(@), 250)

  _refreshComparator: ->
    @searches.comparator = Comparators[@get('sortKey')]

  ###
  Sets the sort key.

  This SearchList will schedule sorts on change, add and reset. You may also
  call sort() to sort immediately.
  ###
  setSortKey: (sortKey) ->
    if sortKey != @get('sortKey')
      @set(sortKey: sortKey)
      @_refreshComparator()
      @sortLater()

  ###
  Indicates that the list has changed a bit and might need sorting.

  SearchList will sort it later.
  ###
  sortLater: -> @_debouncedSortLater()

  ###
  Sorts Searches by the given sortKey.

  We don't sort automatically because query, nDocuments and filterNDocuments
  impact the sort order, and they can change at any time.
  ###
  sort: -> @searches.sort()

  ###
  Returns the Filters as a String.

  @example With a filter
    searchList.addFilter(new Search(query: "foo"))
    searchList.addFilter(new Search(query: "bar"))
    searchList._getFilterString() # "(foo) AND (bar)"

  @example Without a filter
    searchList._getFilterString() # null
  ###
  _getFilterString: ->
    if @filters.length
      @filters
        .map((s) -> "(#{s.get('query')})")
        .join(" AND ")
    else
      null

  _findFiltersFromSearches: ->
    @searches
      .filter((s) -> s.get('filterPosition')?)
      .sort((a, b) -> a.attributes.filterPosition - b.attributes.filterPosition)

  # Calls setFilter() on each Search that is not a filter.
  _refilterNonFilterSearches: ->
    filterString = @_getFilterString()
    @searches
      .filter((s) -> !s.get('filterPosition')?)
      .forEach((s) -> s.setFilter(filterString))

  # Calls setFilter() on each Filter at or after the given index.
  _refilterFilterSearches: (firstIndex) ->
    filterStringArray = []
    @filters.forEach (filter, filterIndex) ->
      if filterIndex >= firstIndex
        if filterStringArray.length
          filter.setFilter(filterStringArray.join(" AND "))
        else
          filter.setFilter(null)
      filterStringArray.push("(#{filter.get('query')})")

  ###
  Makes a Search a Filter.

  This does a few things:

  * Appends `search` to the `filters` attribute.
  * Sets the `filterPosition` attribute of `search`.
  * Runs `setFilter()` on all non-filter Searches.

  @param search [Search] a Search that is not a Filter.
  ###
  addFilter: (search) ->
    @filters.push(search)

    search.set(filterPosition: @filters.length - 1)

    @_refilterNonFilterSearches()

  ###
  Makes a Search *stop* being a Filter.

  This does a few things:

  * Removes `search` from the `filters` attribute.
  * Sets the `filterPosition` attribute of `search` to `null`.
  * Adjusts the `filterPosition` of all later `filters`.
  * Runs `setFilter()` on changed Searches (including the argument).

  @param search [Search] a Search that is not a Filter.
  ###
  removeFilter: (search) ->
    spliceIndex = @filters.indexOf(search)
    @filters.remove(search)

    # Adjust filterPosition
    search.set(filterPosition: null)
    @filters.forEach((s, i) -> s.set(filterPosition: i))

    @_refilterFilterSearches(spliceIndex)
    @_refilterNonFilterSearches()

    undefined

  _onSearchAdded: (model) ->
    filterString = @_getFilterString()
    model.setFilter(filterString)

  _onSearchQueryChanged: (model) ->
    if (position = model.get('filterPosition'))?
      @_refilterFilterSearches(position + 1)
      @_refilterNonFilterSearches()
