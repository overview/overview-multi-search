require('./main.scss') # compile style

Backbone = require('backbone')
$ = Backbone.$ = require('jquery')

App = require('./app')
Searches = require('./collections/Searches')

searchParams = (new URL(document.location)).searchParams
queryString =
  origin: searchParams.get('origin')
  documentSetId: searchParams.get('documentSetId')
  apiToken: searchParams.get('apiToken')

$.ajaxSetup
  beforeSend: (xhr, options) ->
    if options.url.substring(0, queryString.origin.length + 1) == queryString.origin + '/'
      xhr.setRequestHeader('Authorization', "Basic #{window.btoa('' + queryString.apiToken + ':x-auth-token')}")

searches = new Searches([], {
  server: queryString.origin
  documentSetId: queryString.documentSetId
})
searches.fetch()

app = new App
  el: document.querySelector('#app')
  searches: searches
  documentSetId: queryString.documentSetId
app.render()
