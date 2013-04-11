_ = require 'underscore'
phantom = require 'phantom'
db = require '../../../../db'

# resorts = ['arapahoe-basin-ski-area', 'breckenridge']

evalFunction = (page, ph, data, callback)->
	#Inject jQuery
	page.includeJs "//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js", () ->
		console.log 'starting evaluate function'
		page.evaluate ()->
			resultsObj = {}
			results = $('table.snowfall tr:not(.titleRow)')
			for x in [0...results.length]
				cols = $(results[x]).find 'td'
				date = new Date(cols[0].innerHTML)
				
				dateString = (date.getFullYear() * 10000) + ((date.getMonth() + 1) * 100) + date.getDate()
				resultsObj[dateString] = 
					date: date
					dateString: dateString
					newSnowString: cols[1].innerHTML
					newSnowInches: parseInt cols[1].innerHTML.match(/[0-9]+/)[0]
					seasonSnowString: cols[2].innerHTML
					seasonSnowInches: parseInt cols[2].innerHTML.match(/[0-9]+/)[0]
					baseDepthString: cols[3].innerHTML
					baseDepthInches: parseInt cols[3].innerHTML.match(/[0-9]+/)[0]	
			JSON.stringify resultsObj
		, (result)->
			populatePullResults data, result, callback
			ph.exit()

populatePullResults = (data, result, callback) ->
	resultJSON = JSON.parse result
	_.each resultJSON, (v, k) ->
		#Look for existing snowday
		db.SnowDay.findOne {resortName: data.resort.name, snowDateString: v.dateString}, (err, result) ->

			#find or create
			if result
				console.log 'found existing snowday: %s, skipping', result.snowDateString
				# snowDay = result
			else
				console.log 'creating new snowday'
				snowDay = new db.SnowDay()
				#update attrs
				snowDay.resortName = data.resort.name
				snowDay.resortId = data.resort._id
				snowDay.snowDate = v.date
				snowDay.snowDateString = v.dateString
				snowDay.snowBase = v.baseDepthInches
				snowDay.precipitation = v.newSnowInches
				snowDay.seasonSnow = v.seasonSnowInches
				snowDay.save (err) ->
					if err
						console.log 'error saving snow day'
					else
						console.log 'snow day saved'
	callback resultJSON

scrapePage = (url, data, callback) ->
	console.log 'creating phantom instance for %s', url
	phantom.create (ph)->
		console.log 'creating phantom page for %s', url 
		ph.createPage (page)->
			console.log 'phantom page created for %s', url
			page.onConsoleMessage = (msg) -> console.log msg
			page.open url, (status)->
				console.log 'Opening site: ', url
				console.log 'Opened site? ', status
				evalFunction page, ph, data, callback

exports.scrape = (resort, callback) ->
	if !resort then return
	years = ['2009', '2010', '2011', '2012', '2013']
	for i in [0...years.length]
		url = 'http://www.onthesnow.com/colorado/' + resort.name + '/historical-snowfall.html?&y=' + years[i] + '&q=base&v=list#view'
		scrapePage url, {resort: resort, year: years[i]}, callback
