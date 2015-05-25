Backbone = require('backbone')
Search = require('../../js/models/Search')

describe 'Search', ->
  beforeEach ->
    @sandbox = sinon.sandbox.create()
    @sandbox.stub(Backbone, 'ajax')
    @sandbox.stub(Search.prototype, 'save', (args...) -> Search.prototype.set.apply(@, args))
    @subject = new Search(id: 'id', query: 'q1')
    @subject.collection = { documentSetId: 'dsid', server: 'http://server' }

  afterEach ->
    @subject.off()
    @sandbox.restore()

  describe '#parse', ->
    it 'should grab id and query', ->
      ret = Search.prototype.parse(id: 'i1', json: { query: 'q1' })
      expect(ret.id).to.eq('i1')
      expect(ret.query).to.eq('q1')

  describe 'with a typical Search', ->
    it 'should have nDocuments=null', ->
      expect(@subject.get('nDocuments')).to.be.null

    it 'should have error=null', ->
      expect(@subject.get('error')).to.be.null

    it 'should have filter=null', ->
      expect(@subject.get('filter')).to.be.null

    it 'should have filterNDocuments=null', ->
      expect(@subject.get('filterNDocuments')).to.be.null

    it 'should have filterError=null', ->
      expect(@subject.get('filterError')).to.be.null

    describe '#refresh', ->
      it 'should call Backbone.ajax', ->
        @subject.refresh()
        expect(Backbone.ajax).to.have.been.called
        expect(Backbone.ajax.firstCall.args[0]).to.have.property('success')
        expect(Backbone.ajax.firstCall.args[0]).to.have.property('error')

      it 'should build the right URL', ->
        @subject.refresh()
        expect(Backbone.ajax.firstCall.args[0]).to.have.property(
          'url',
          'http://server/api/v1/document-sets/dsid/documents?fields=id&q=q1&refresh=true'
        )

      it 'should urlEncode the query in the URL', ->
        @subject.set(query: 'foo bar[]')
        @subject.refresh()
        expect(Backbone.ajax.firstCall.args[0]).to.have.property(
          'url',
          'http://server/api/v1/document-sets/dsid/documents?fields=id&q=foo%20bar%5B%5D&refresh=true'
        )

      it 'should set nDocuments on success', ->
        @subject.refresh()
        Backbone.ajax.firstCall.args[0].success([ 123, 234, 345 ])
        expect(@subject.get('nDocuments')).to.eq(3)
        expect(@subject.get('error')).to.be.null

      it 'should set error on failure', ->
        @subject.refresh()
        Backbone.ajax.firstCall.args[0].error(responseJSON: { message: 'm1' })
        expect(@subject.get('nDocuments')).to.be.null
        expect(@subject.get('error')).to.deep.eq(message: 'm1')

      it 'should ignore an obsolete success', ->
        @subject.refresh()
        @subject.set(query: 'foo')
        @subject.refresh()
        Backbone.ajax.firstCall.args[0].success([ 123, 234, 345 ])
        expect(@subject.get('nDocuments')).to.be.null
        expect(@subject.get('error')).to.be.null

      it 'should ignore an obsolete error', ->
        @subject.refresh()
        @subject.set(query: 'foo')
        @subject.refresh()
        Backbone.ajax.firstCall.args[0].error(responseJSON: { message: 'm1' })
        expect(@subject.get('nDocuments')).to.be.null
        expect(@subject.get('error')).to.be.null

      describe 'with a filter', ->
        beforeEach -> @subject.set(filter: '(f1) AND (f2)')

        it 'should include the filter in the URL', ->
          @subject.set(filter: '(f1) AND (f2)')
          @subject.refresh()
          expect(Backbone.ajax.firstCall.args[0]).to.have.property(
            'url',
            'http://server/api/v1/document-sets/dsid/documents?fields=id&q=(f1)%20AND%20(f2)%20AND%20(q1)&refresh=true'
          )

        it 'should set filterNDocuments on success', ->
          @subject.set(filter: '(f1) AND (f2)')
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].success([ 123, 234, 345 ])
          expect(@subject.get('filterNDocuments')).to.eq(3)
          expect(@subject.get('filterError')).to.be.null

        it 'should set filterError on failure', ->
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].error({ responseJSON: { message: 'm1' }})
          expect(@subject.get('filterNDocuments')).to.be.null
          expect(@subject.get('filterError')).to.deep.eq(message: 'm1')

        it 'should ignore an obsolete success after the filter changes', ->
          @subject.refresh()
          @subject.setFilter('(f2)')
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].success([ 123, 234, 345 ])
          expect(@subject.get('filterNDocuments')).to.be.null
          expect(@subject.get('filterError')).to.be.null

        it 'should ignore an obsolete error after the filter changes', ->
          @subject.refresh()
          @subject.setFilter('(f2)')
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].error(responseJSON: { message: 'm1' })
          expect(@subject.get('filterNDocuments')).to.be.null
          expect(@subject.get('filterError')).to.be.null

        it 'should ignore an obsolete success after the query changes', ->
          @subject.refresh()
          @subject.setQuery('q2')
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].success([ 123, 234, 345 ])
          expect(@subject.get('filterNDocuments')).to.be.null
          expect(@subject.get('filterError')).to.be.null

        it 'should ignore an obsolete error after the query changes', ->
          @subject.refresh()
          @subject.setQuery('q2')
          @subject.refresh()
          Backbone.ajax.firstCall.args[0].error(responseJSON: { message: 'm1' })
          expect(@subject.get('filterNDocuments')).to.be.null
          expect(@subject.get('filterError')).to.be.null

    describe '#refreshIfNeeded()', ->
      beforeEach ->
        @subject.refresh = sinon.spy()

      it 'should refresh if there is no nDocuments', ->
        @subject.set(filter: null, nDocuments: null)
        @subject.refreshIfNeeded()
        expect(@subject.refresh).to.have.been.called

      it 'should not refresh if there is nDocuments', ->
        @subject.set(filter: null, nDocuments: 0)
        @subject.refreshIfNeeded()
        expect(@subject.refresh).not.to.have.been.called

      it 'should refresh if there is a filter and no filterNDocuments', ->
        @subject.set(filter: '(f1)', filterNDocuments: null)
        @subject.refreshIfNeeded()
        expect(@subject.refresh).to.have.been.called

      it 'should not refresh if there is a filter and filterNDocuments', ->
        @subject.set(filter: '(f1)', filterNDocuments: 0, nDocuments: null)
        @subject.refreshIfNeeded()
        expect(@subject.refresh).not.to.have.been.called

    describe '#setQuery()', ->
      it 'should set the query', ->
        @subject.setQuery('q2')
        expect(@subject.get('query')).to.eq('q2')

      it 'should unset error and nDocuments', ->
        @subject.set(error: { message: 'm1' }, nDocuments: 123)
        @subject.setQuery('q2')
        expect(@subject.get('error')).to.be.null
        expect(@subject.get('nDocuments')).to.be.null

      it 'should do nothing when not changing', ->
        @subject.set(error: { message: 'm1' }, nDocuments: 123)
        @subject.setQuery('q1')
        expect(@subject.get('error')).to.deep.eq(message: 'm1')
        expect(@subject.get('nDocuments')).to.eq(123)

    describe '#setFilter()', ->
      it 'should set the filter', ->
        @subject.setFilter('(f1)')
        expect(@subject.get('filter')).to.eq('(f1)')

      it 'should unset filterError and filterNDocuments', ->
        @subject.set(filterError: { message: 'm1' }, filterNDocuments: 123)
        @subject.setFilter('(f1)')
        expect(@subject.get('filterError')).to.be.null
        expect(@subject.get('filterNDocuments')).to.be.null

      it 'should do nothing when not changing', ->
        @subject.setFilter('(f1)')
        @subject.set(filterError: { message: 'm1' }, filterNDocuments: 123)
        @subject.setFilter('(f1)')
        expect(@subject.get('filterError')).to.deep.eq(message: 'm1')
        expect(@subject.get('filterNDocuments')).to.eq(123)

      it 'should unset the filter, filterError and filterNDocuments', ->
        @subject.set(filter: 'f1', filterError: {message: 'm1'}, filterNDocuments: 123)
        @subject.setFilter(null)
        expect(@subject.get('filter')).to.be.null
        expect(@subject.get('filterError')).to.be.null
        expect(@subject.get('filterNDocuments')).to.be.null
