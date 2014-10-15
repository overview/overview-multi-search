_ = require('lodash')
Backbone = require('backbone')

# An search. Has a name and some terms.
module.exports = class Search extends Backbone.Model
  defaults:
    name: ''
    terms: []
    nDocuments: 0

  parse: (json) -> _.extend({ id: json.id }, json.json)
  toJSON: -> { json: @attributes }
