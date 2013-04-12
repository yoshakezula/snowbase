express = require "express"
path = require "path" 
http = require 'http'
mongoose = require 'mongoose'
stylus = require 'stylus'
nib = require 'nib'
models = require './db'
routes = require './routes'

app = express()

mongoose.connect 'mongodb://localhost/ski-app'

compile = (str, path) ->
  stylus(str).set('filename', path).set('compress', true).use nib()

app.configure () ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  # app.set 'view options', layout: false
  app.use stylus.middleware
    src: __dirname + '/public'
    compile: compile
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router

app.configure 'development', () ->
  app.use express.errorHandler()

routes.init app

http.createServer(app).listen 3000
console.log "Express server listening on port 3000"
