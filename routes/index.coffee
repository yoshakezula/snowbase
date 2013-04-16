request = require 'request'
_ = require 'underscore'

exports.init = (app) ->
	app.get '/', (req, res) ->
		res.render 'index', title: "SnowBase - Compare This Year's Snow Base Depth to the Past"

	app.get '/api/resorts', (req, res) ->
		request {url: 'http://snowbase-api.kennychan.co/resorts', json: true}, (error, response, body) ->
				if !error && response.statusCode == 200
					res.send body
				else
					res.send 'error'

	app.get '/api/snow-days', (req, res) ->
		request {url: 'http://snowbase-api.kennychan.co/snow-days', json: true}, (error, response, body) ->
				if !error && response.statusCode == 200
					res.send body
				else
					res.send 'error'

	app.get '/api/snow-days/:name', (req, res) ->
		request {url: 'http://snowbase-api.kennychan.co/snow-days/' + req.params.name, json: true}, (error, response, body) ->
				if !error && response.statusCode == 200
					res.send body
				else
					res.send 'error'