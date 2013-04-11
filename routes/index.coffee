scraper = require '../public/js/libs/scraper'
db = require '../db'
_ = require 'underscore'

addResort = (req, res, callback) ->
	db.Resort.find name: req.params.name, (err, results) ->
		if results.length > 0
			console.log 'resort already in database'
			callback results[0]
		else
			resort = new db.Resort
				name: req.params.name
			resort.save (err) ->
				if !err
					console.log 'created new resort'
					callback resort
				else
					callback 'error'

deleteResort = (req, res, callback) ->
	db.Resort.findById req.params.id, (err, results) ->
		results.remove (err) ->
			if !err
				res.redirect '/api/resorts'
				console.log 'deleted'
				callback results
			else
				res.send 'error deleting'

exports.init = (app) ->
	app.get '/', (req, res) ->
		res.render 'index', title: "SnowBase - Compare This Year's Snow Base Depth to the Past"

	app.get '/api/add-resort/:name', (req, res) ->
		addResort req, res, (results) -> 
			res.send results

	app.get '/api/delete-resort/:id', deleteResort
	
	app.get '/api/pull/:name', (req, res) ->
		addResort req, res, (results) ->
			if results == 'error'
				res.send 'error'
			else
				scraper.scrape results, (results) ->
					res.send results

	app.get '/api/resorts', (req, res) ->
		db.Resort.find (err, results) ->
			res.send results

	app.get '/api/snow-days', (req, res) ->
		db.SnowDay.find (err, results) ->
			res.send results

	app.get '/api/normalize-snow-data', (req, res) ->
		db.normalizeSnowData (results) ->
			res.send results

	app.get '/api/remove-duplicates', (req, res) ->
		db.removeDuplicates (output) ->
			res.send output
		# res.redirect '/api/snow-days'

	app.get '/api/delete-snowdays', (req, res) ->
		db.SnowDay.find (err, results) ->
			_.each results, (snowDay) ->
				snowDay.remove (err) ->
					if !err then console.log 'removed snowday %s', snowDay._id
			res.redirect '/api/snow-days'

	app.get '/api/resorts/:name', (req, res) ->
		db.Resort.findOne name: req.params.name, (err, results) ->
			res.send results
