phantom = require 'phantom'

evalFunction = (page, ph)->
	# query page for results
	page.includeJs "//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js", () ->

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
			console.log result
			ph.exit()

scrapePage = (url) ->
	phantom.create (ph)->
			# page.open 'http://www.onthesnow.com/colorado/breckenridge/historical-snowfall.html?&y=2012&q=base&v=list#view', (status)->
			# 	console.log 'Opened site? ', status
			# 	evalFunction page, ph
		ph.createPage (page)->
			page.onConsoleMessage = (msg) -> console.log msg
			page.open url, (status)->
				console.log 'Opened site? ', status
				evalFunction page, ph

scrape = () ->
	resorts = ['arapahoe-basin-ski-area', 'breckenridge']
	# years = ['2009', '2010', '2011', '2012', '2013']
	years = ['2012']
	for j in [0...resorts.length]
		for i in [0...years.length]
			url = 'http://www.onthesnow.com/colorado/' + resorts[j] + '/historical-snowfall.html?&y=' + years[i] + '&q=base&v=list#view'
			scrapePage url

