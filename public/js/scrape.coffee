# Success: Testing for wikipedia
phantom = require 'phantom'
phantom.create (ph)->
	ph.createPage (page)->
		page.open 'http://en.wikipedia.org/wiki/Main_Page', (status)->
			console.log 'Opened site? %s', status
			evalFunction page, ph
						
evalFunction = (page, ph)->
	# query page for results
	page.includeJs "//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js", () ->

		page.evaluate ()->
		
			# function needs to be within the page evaluate callback
			getContents = ()->
				h2Arr = []
				# results = document.querySelectorAll('p')
				results = $('p')
				for x in [0...results.length]
					h2Arr.push(results[x].innerHTML)
					console.log(results[x])
				h2Arr
							
			h2Arr = []
			h2Arr = getContents()
			h2: h2Arr

		, (result)->
			console.log result
			ph.exit()
