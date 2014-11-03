csv = require('csv')

class CsvDialect
  stringify: (json, done) ->
    options =
      columns: [ 'name', 'query' ]
    csv.stringify(json, options, done)

  parse: (csvString, done) ->
    options =
      columns: [ 'name', 'query' ]
      comment: null
      trim: true
      skip_empty_lines: true
    # node-csv-parser breaks with empty input
    if csvString
      csv.parse(csvString, options, done)
    else
      done(null, [])

module.exports =
  withDialect: (dialect) ->
    throw new Error("Dialect must be 'csv'") if dialect != 'csv'

    new CsvDialect
