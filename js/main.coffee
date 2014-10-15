Backbone = require('backbone')
$ = Backbone.$ = require('jquery')

App = require('./app')
Searches = require('./collections/Searches')

queryString = (->
  map = {}

  list = window.location.search
    .split(/[\?&]/g)
    .map((x) -> x.split('=', 2))

  for x in list
    map[decodeURIComponent(x[0])] = decodeURIComponent(x[1])

  map
)()

$.ajaxSetup
  beforeSend: (xhr, options) ->
    if options.url.substring(0, queryString.server.length) == queryString.server
      xhr.setRequestHeader('Authorization', "Basic #{new Buffer("" + queryString.apiToken + ":x-auth-token").toString('base64')}")

global.server = queryString.server

$ ->
  searches = new Searches([], {
    server: queryString.server
    vizId: queryString.vizId
  })
  searches.fetch()

  app = new App
    el: $('#app')[0]
    searches: searches
    documentSetId: queryString.documentSetId
  app.render()
