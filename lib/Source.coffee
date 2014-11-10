csv = require('csv')

# Returns "s" if it doesn't need quoting, or '"s"' if it does
#
# XXX Undefined behavior if we're quoting a quotation mark
cleanQuote = (s) ->
  if /[^a-zA-Z0-9_]/.test(s)
    '"' + s + '"'
  else
    s

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
      csv.parse csvString, options, (err, objs) ->
        return done(err) if err?

        objs.forEach((obj) -> obj.query ?= cleanQuote(obj.name))
        done(err, objs)
    else
      done(null, [])

module.exports =
  withDialect: (dialect) ->
    throw new Error("Dialect must be 'csv'") if dialect != 'csv'

    new CsvDialect
