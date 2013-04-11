scraper = require '../public/js/libs/scraper'
db = require '../db'
_ = require 'underscore'
# results = scraper.scrape()

addResort = (req, res, callback) ->
	db.Resort.find name: req.params.name, (err, results) ->
		if results.length > 0
			console.log 'resort already in database'
			res.redirect '/api/resorts'
			callback results
		else
			resort = new db.Resort
				name: req.params.name
			resort.save (err) ->
				if !err
					res.redirect '/api/resorts'
					console.log 'created new resort'
					callback results
				else
					res.send 'error'

deleteResort = (req, res, callback) ->
	db.Resort.findById req.params.id, (err, results) ->
		results.remove (err) ->
			if !err
				res.redirect '/api/resorts'
				console.log 'deleted'
				callback results
			else
				res.send 'error deleting'

# populatePullResults = (results) ->
# 	console.log 'callback starting'
# 	console.log results

exports.init = (app) ->
	app.get '/', (req, res) ->
		res.render 'index', title: "SnowBase - Compare This Year's Snow Base Depth to the Past"

	app.get '/add-resort/:name', addResort

	app.get '/delete-resort/:id', deleteResort
	
	app.get '/pull/:name', (req, res) ->
		results = addResort req, res, (results) ->
			scraper.scrape results

	app.get '/api/resorts', (req, res) ->
		db.Resort.find (err, results) ->
			res.send results

	app.get '/api/snow-days', (req, res) ->
		db.SnowDay.find (err, results) ->
			res.send results

	app.get '/api/normalize-snow-data', (req, res) ->
		db.normalizeSnowData()
		res.redirect '/api/snow-days'

	app.get '/api/remove-duplicates', (req, res) ->
		db.removeDuplicates (output) ->
			res.send output
		# res.redirect '/api/snow-days'

	app.get '/delete-snowdays', (req, res) ->
		db.SnowDay.find (err, results) ->
			_.each results, (snowDay) ->
				snowDay.remove (err) ->
					if !err then console.log 'removed snowday %s', snowDay._id
			res.redirect '/api/snow-days'

	app.get '/api/resorts/:name', (req, res) ->
		db.Resort.findOne name: req.params.name, (err, results) ->
			res.send results
