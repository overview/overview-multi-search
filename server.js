#!/usr/bin/env node
'use strict'

const express = require('express')
const morgan = require('morgan')

const app = express()

app.use(morgan('dev'))

app.use((req, res, next) => {
  if (req.path === '/show' || req.path === '/metadata') {
    res.set('Content-Type', 'text/html')
  }

  res.set('Access-Control-Allow-Origin', '*')
  next()
})

app.use(express.static(`${__dirname}/dist`))

const port = parseInt(process.env.PORT, 10) || 3000
app.listen(port, () => {
  console.log(`Listening on http://localhost:${port}`)
})

