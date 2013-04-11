express = require "express"
path = require "path" 
http = require 'http'
mongoose = require 'mongoose'
stylus = require 'stylus'
nib = require 'nib'
models = require './db'
routes = require './routes'
# For coffeescript: https://github.com/adunkman/connect-assets
app = express()

mongoURIString = process.env.MONGOLAB_URI || 
process.env.MONGOHQ_URL || 
'mongodb://localhost/ski-app'
mongoose.connect mongoURIString, (err, res) ->
  console.log if err then 'ERROR connecting to ' + mongoURIString + '. ' + err else 'Succeeded connecting to ' + mongoURIString

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

port = process.env.PORT || 3000
http.createServer(app).listen port
console.log "Express server listening on port " + port
