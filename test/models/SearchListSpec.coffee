Backbone = require('backbone')
SearchList = require('../../js/models/SearchList')

describe 'models/SearchList', ->
  class Search extends Backbone.Model
    setFilter: (filter) ->

  class Searches extends Backbone.Collection
    model: Search

  beforeEach ->
    @searches = new Searches([
      new Search(id: 'abc', name: 'n0', query: 'q0')
      new Search(id: 'bcd', name: 'n1', query: 'q1')
      new Search(id: 'cde', name: 'n2', query: 'q2')
    ])

    @search0 = @searches.at(0)
    @search1 = @searches.at(1)
    @search2 = @searches.at(2)
    @search0.setFilter = sinon.spy()
    @search1.setFilter = sinon.spy()
    @search2.setFilter = sinon.spy()

    @subject = new SearchList({}, searches: @searches, sortLater: sinon.spy())
    @filters = @subject.filters

  afterEach ->
    @subject.off()

  it 'should have @searches', ->
    expect(@subject.searches).to.eq(@searches)

  it 'should have @filters, starting empty', ->
    expect(@subject.filters).to.have.property('length', 0)

  it 'should populate @filters from @searches', ->
    @search1.set(filterPosition: 1)
    @search2.set(filterPosition: 0)

    subject2 = new SearchList({}, searches: @searches, sortLater: sinon.spy())
    expect(subject2.filters.pluck('id')).to.deep.eq([ 'cde', 'bcd' ])

  it 'should set @searches.comparator by default, so add() sorts immediately', ->
    expect(@searches.comparator).to.exist

  describe '#defaults', ->
    it 'should have sortKey=name-asc', ->
      expect(@subject.get('sortKey')).to.eq('name-asc')

  describe '#setSortKey()', ->
    it 'should change sort-key', ->
      @subject.setSortKey('n-documents-desc')
      expect(@subject.get('sortKey')).to.eq('n-documents-desc')

    it 'should call sortLater()', ->
      @subject.sortLater = sinon.spy()
      @subject.setSortKey('n-documents-desc')
      expect(@subject.sortLater).to.have.been.called

    it 'should set @searches.comparator, so add() sorts immediately', ->
      comparator1 = @subject.comparator
      @subject.setSortKey('n-documents-desc')
      expect(@searches.comparator).not.to.eq(comparator1)

  describe '#sortLater()', ->
    it 'should not call sortLater() when the sort key does not change', ->
      @subject.setSortKey(@subject.get('sortKey'))
      expect(@subject.sortLater).not.to.have.been.called

    it 'should call sortLater() when the name changes', ->
      @search0.set(name: 'n0-1')
      expect(@subject.sortLater).to.have.been.called

    it 'should call sortLater() on fetch', ->
      @searches.trigger('fetch')
      expect(@subject.sortLater).to.have.been.called

    it 'should call sortLater() on reset', ->
      @searches.trigger('fetch')
      expect(@subject.sortLater).to.have.been.called

    it 'should not call sortLater() on add()', ->
      # We use the comparator for add(), not sortLater()
      @searches.add(new Search(id: 4, query: 'q4'))
      expect(@subject.sortLater).not.to.have.been.called

  describe '#addFilter', ->
    it 'should add to the empty list', ->
      @subject.addFilter(@search1)
      expect(@filters.pluck('id')).to.deep.eq([ 'bcd' ])

    it 'should add to an existing filter', ->
      @subject.addFilter(@search1)
      @subject.addFilter(@search0)
      expect(@filters.pluck('id')).to.deep.eq([ 'bcd', 'abc' ])

    it 'should call setFilter() on non-filter Searches on change:query', ->
      @subject.addFilter(@search1)
      @search1.set(query: 'q1-1')
      expect(@search0.setFilter).to.have.been.calledWith('(q1-1)')
      expect(@search2.setFilter).to.have.been.calledWith('(q1-1)')

    it 'should call setFilter() on later filter Searches on change:query', ->
      @subject.addFilter(@search1)
      @subject.addFilter(@search0)
      @search1.set(query: 'q1-1')
      expect(@search0.setFilter).to.have.been.calledWith('(q1-1)')

    describe 'starting empty', ->
      it 'should call setFilter() on non-included Searches', ->
        @subject.addFilter(@search1)
        expect(@search0.setFilter).to.have.been.calledWith('(q1)')
        expect(@search1.setFilter).not.to.have.been.called
        expect(@search2.setFilter).to.have.been.calledWith('(q1)')

      it 'should set filterPosition on the filter', ->
        @subject.addFilter(@search1)
        expect(@search1.get('filterPosition')).to.eq(0)

    describe 'starting with a search', ->
      beforeEach -> @subject.addFilter(@search1)

      it 'should call setFilter() on non-included Searches', ->
        @search0.setFilter = sinon.spy() # Reset the spy
        @subject.addFilter(@search0)
        expect(@search0.setFilter).not.to.have.been.called
        expect(@search1.setFilter).not.to.have.been.called
        expect(@search2.setFilter).to.have.been.calledWith('(q1) AND (q0)')

  describe '#removeFilter', ->
    it 'should unset filterPosition', ->
      @subject.addFilter(@search1)
      @subject.removeFilter(@search1)
      expect(@search1.get('filterPosition')).not.to.exist

    describe 'starting with one filter', ->
      beforeEach ->
        @subject.addFilter(@search1)

      it 'should call setFilter(null) on non-included Searches', ->
        @subject.removeFilter(@search1)
        expect(@search0.setFilter).to.have.been.calledWith(null)
        expect(@search2.setFilter).to.have.been.calledWith(null)

      it 'should call setFilter(null) on the Search', ->
        @subject.removeFilter(@search1)
        expect(@search1.setFilter).to.have.been.calledWith(null)

    describe 'starting with two filters', ->
      beforeEach ->
        @subject.addFilter(@search1)
        @subject.addFilter(@search0)

      it 'should remove a filter from the end of the list', ->
        @subject.removeFilter(@search0)
        expect(@filters.pluck('id')).to.deep.eq([ 'bcd' ])

      it 'should remove a filter from the beginning of the list', ->
        @subject.removeFilter(@search1)
        expect(@filters.pluck('id')).to.deep.eq([ 'abc' ])

      it 'should set filterPosition on non-removed filters', ->
        @subject.removeFilter(@search1)
        expect(@search0.get('filterPosition')).to.eq(0)

      it 'should call setFilter() on non-included Searches', ->
        @subject.removeFilter(@search1)
        expect(@search2.setFilter).to.have.been.calledWith('(q0)')

      it 'should call setFilter() on the removed Search', ->
        @subject.removeFilter(@search1)
        expect(@search1.setFilter).to.have.been.calledWith('(q0)')

      it 'should call setFilter() on the next filter Search', ->
        @subject.addFilter(@search2)
        @subject.removeFilter(@search1)
        expect(@search0.setFilter).to.have.been.calledWith(null)
        expect(@search2.setFilter).to.have.been.calledWith('(q0)')

      it 'should not call setFilter() on previous filter Searches', ->
        @subject.removeFilter(@search0)
        expect(@search1.setFilter).not.to.have.been.called

      it 'should stop calling setFilter() on other Searches on change:query', ->
        @subject.removeFilter(@search1)

        # Stuff changed. Reset spies.
        @search0.setFilter = sinon.spy()
        @search1.setFilter = sinon.spy()
        @search2.setFilter = sinon.spy()

        @search1.set(query: 'q1-1')
        expect(@search0.setFilter).not.to.have.been.called
        expect(@search1.setFilter).not.to.have.been.called
        expect(@search2.setFilter).not.to.have.been.called
