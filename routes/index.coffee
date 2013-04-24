request = require 'request'
url = require 'url'

exports.init = (app) ->
  app.get '/', (req, res) ->
    res.render 'index', title: "Snowbase - Compare Base Depth Across Resorts"

  app.get '/api/resorts', (req, res) ->
    request {url: 'https://snowbase-api.s3.amazonaws.com/resort_map.json', json: true}, (error, response, body) ->
        if !error && response.statusCode == 200
          res.send body
        else
          res.send 'error'

  app.get '/api/snow-days', (req, res) ->
    query = url.parse(req.url, true).query
    request {url: 'http://snowbase-api.kennychan.co/api/snow-days', json: true, qs: query}, (error, response, body) ->
        if !error && response.statusCode == 200
          res.send body
        else
          res.send 'error'

  app.get '/api/snow-days-map', (req, res) ->
    request {url: 'https://snowbase-api.s3.amazonaws.com/snow_day_map.json', json: true}, (error, response, body) ->
        if !error && response.statusCode == 200
          res.send body
        else
          res.send error