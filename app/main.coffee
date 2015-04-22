express = require('express')
morgan = require('morgan')
serveStatic = require('serve-static')

app = express()

app.use(morgan('dev'))

app.use (req, res, next) ->
  if req.path in [ '/show', '/metadata' ]
    res.set('Content-Type', 'text/html')

  res.set('Access-Control-Allow-Origin', '*')
  next()

app.use(serveStatic('dist'))

port = parseInt(process.env.PORT, 10) || 9001
app.listen(port)
console.log("Listening on http://localhost:#{port}")
