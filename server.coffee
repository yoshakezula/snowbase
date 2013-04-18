express = require "express"
path = require "path" 
http = require 'http'
stylus = require 'stylus'
nib = require 'nib'
routes = require './routes'
app = express()

compile = (str, path) ->
  stylus(str).set('filename', path).set('compress', true).use nib()

# app.set 'env', process.env.NODE_ENV || 'development'

app.configure () ->
  app.set 'views', __dirname + '/views'
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger('dev')
  app.use express.static(__dirname + '/public')
  app.use express.bodyParser()
  app.use express.methodOverride()
  # app.use stylus.middleware
  #   src: __dirname + '/public'
  #   compile: compile
  app.use app.router

app.configure 'development', () ->
  app.use express.errorHandler()


routes.init app

port = process.env.PORT || 3000
http.createServer(app).listen port
console.log "Express server listening on port " + port
console.log "Environment: " + process.env.NODE_ENV
