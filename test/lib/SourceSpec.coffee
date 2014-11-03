Source = require('../../lib/Source')

describe 'Source', ->
  describe 'withDialect("csv")', ->
    beforeEach -> @subject = Source.withDialect('csv')

    describe '#stringify', ->
      test = (json, csv, description) ->
        it "should #{description}", (done) ->
          @subject.stringify json, (err, result) ->
            expect(err).to.be.null
            expect(result).to.deep.eq(csv)
            done()

      test([], '', 'stringify the empty set')
      test([{ name: 'foo', query: 'bar' }], 'foo,bar\n', 'stringify name and query')
      test([{ name: 'foo', query: 'bar, baz' }], 'foo,"bar, baz"\n', 'escape commas')
      test([{ name: 'foo', query: 'bar"baz' }], 'foo,"bar""baz"\n', 'escape quotes')
      test([{ name: 'foo', query: 'bar\nbaz' }], 'foo,"bar\nbaz"\n', 'escape newlines')
      test([{ name: 'foo', query: 'bar' }, { name: 'bar', query: 'baz' }], 'foo,bar\nbar,baz\n', 'stringify multiple lines')

    describe '#parse', ->
      test = (csv, json, description) ->
        it "should #{description}", (done) ->
          @subject.parse csv, (err, result) ->
            expect(err).to.be.null
            expect(result).to.deep.eq(json)
            done()

      test('', [], 'parse the empty set')
      test(' \n ', [], 'ignore whitespace when parsing the empty set')
      test('foo,bar', [ { name: 'foo', query: 'bar' } ], 'parse a simple object')
      test('foo,bar\nbar,baz', [{ name: 'foo', query: 'bar' }, { name: 'bar', query: 'baz' }], 'parse multiple objects')
      test('foo,"bar,baz"', [{ name: 'foo', query: 'bar,baz' }], 'parse a comma')
      test('foo,"bar\nbaz"', [{ name: 'foo', query: 'bar\nbaz' }], 'parse a newline')
      test('foo,"bar""baz"', [{ name: 'foo', query: 'bar"baz' }], 'parse a quote')

      it 'should return error on unclosed quote', (done) ->
        @subject.parse 'foo,bar\nfoo,"bar\nbar,baz', (err, result) ->
          expect(result).not.to.exist
          expect(err).to.exist
          expect(err).to.have.property('message', 'Quoted field not terminated at line 2')
          done()

      it 'should return error on misplaced quote', (done) ->
        @subject.parse 'foo,ba"r\nbar,ba"z', (err, result) ->
          expect(result).not.to.exist
          expect(err).to.exist
          expect(err).to.have.property('message', 'Invalid opening quote at line 1')
          done()
