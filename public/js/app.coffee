$ ->
	console.log 'main script loaded'
	class Resort extends Backbone.Model
		idAttribute: "_id"

	# class SnowDay extends Backbone.Model
	# 	idAttribute: "_id"

	# class SnowDayCollection extends Backbone.Collection
	# 	model: SnowDay
	# 	url: 'http://snowbase-api/snow-days'
	# 	initialize: () ->
	# 		@_resortMap = {}
	# 		@_correctedResortMap = {}
	# 		@on 'add', @_addModelToMaps
	# 		@on 'reset', @_addAllModelsToMaps

	# 	_addModelToMaps: (model) ->
	# 		resortName = model.get 'resortName'
	# 		date = new Date(model.get 'snowDate')
	# 		#Start season in November (month 10)
	# 		if date.getMonth() > 9
	# 			season = date.getFullYear() + '-' + (date.getFullYear() + 1).toString().slice(-2)
	# 		#end season in april (month 3)
	# 		else if date.getMonth() < 4
	# 			season = (date.getFullYear() - 1) + '-' + date.getFullYear().toString().slice(-2)
	# 		else
	# 			return
	# 		if !@_resortMap[resortName]
	# 			@_resortMap[resortName] = {}
	# 		if !@_resortMap[resortName][season]
	# 			@_resortMap[resortName][season] = {}
	# 		@_resortMap[resortName][season][model.get 'snowDateString'] = model

	# 	_addAllModelsToMaps: () ->
	# 		@_resortMap = {}
	# 		_.each @models, (model) =>
	# 			@_addModelToMaps model

	class ResortCollection extends Backbone.Collection
		model: Resort
		url: 'http://snowbase-api.kennychan.co/resorts'

	# SnowDays = new SnowDayCollection()	
	Resorts = new ResortCollection()
	
	class ResortView extends Backbone.View
		className: 'resort-list-item'
		events:
			'click' : 'clickHandler'

		clickHandler: () ->
			Backbone.Events.trigger 'resortClicked', @model

		render: () ->
			@$el.html @model.get 'name'
			@

	class ResortDataPane extends Backbone.View
		el: $ '#resort-data-pane'
		initialize: ()->
			@dataMap = {}
			@chartData = []
			@listenTo Backbone.Events, 'resortClicked', @clickHandler
			@paletteStep = -1
			@rgba = $('html').hasClass 'rgba'
			@paletteHEX = [
				'#C6E774'
				# '#337EFF'
				'#70A5FF'
				'#85B1FF'
				'#99BEFF'
				'#ADCBFF'
				'#C2D8FF'
				'#D6E5FF'
				'#EBF2FF'
			]
			@paletteRGBA = _.map @paletteHEX, (color) => @colorToRGBA(color).rgba


		colorToRGBA: (r, g, b) ->
			if g == undefined && typeof r == 'string'
				#it's a hex string
				r = r.replace /^\s*#|\s*$/g, ''
				if r.length == 3
					r.replace /(.)/g, '$1$1'
				g = parseInt r.substr(2,2), 16
				b = parseInt r.substr(4,2), 16
				r = parseInt r.substr(0,2), 16

				min = Math.min r, g, b
				a = (255 - min) / 255

				r: r = 0 | (r - min) / a
				g: g = 0 | (g - min) / a
				b: b = 0 | (b - min) / a
				a: a = (0|1000*a)/1000
				rgba: 'rgba(' + r + ', ' + g + ', ' + b + ', ' + a + ')'

		getColor: () ->
			@paletteStep += 1
			if @rgba
				@paletteRGBA[@paletteStep] || @paletteRGBA[@paletteRGBA.length - 1]
			else
				@paletteHEX[@paletteStep] || @paletteHEX[@paletteHEX.length - 1]


		renderChart: () ->
			@$('.rickshaw_graph, .legend, .chart-slider').remove()
			@$('#resort-data').html('<div class="rickshaw_graph"></div><div class="legend"></div><div class="chart-slider"></div>')
			chartWidth = ($(window).width() * (.829 - .0256)) - 40
			chartHeight = 500
			if _.size(@chartData) == 0
				return

			graph = new Rickshaw.Graph
				element: @$('.rickshaw_graph')[0]
				width: chartWidth
				height: chartHeight
				stroke: true
				renderer: if @rgba then 'area' else 'line'
				series: @chartData
				interpolation: 'basis'
				# min: 'auto'

			graph.renderer.unstack = true
			graph.render()
			@$('rickshaw_graph').addClass 'come-in'

			legend = new Rickshaw.Graph.Legend
				graph: graph
				element: @$('.legend')[0]

			shelving = new Rickshaw.Graph.Behavior.Series.Toggle
				graph: graph
				legend: legend

			highlighter = new Rickshaw.Graph.Behavior.Series.Highlight
				graph: graph
				legend: legend

			Hover = Rickshaw.Class.create Rickshaw.Graph.HoverDetail, 
				render: (args) ->
					# console.log args

					thisSeason = _.last _.sortBy(args.detail, (series) -> series.name)
					otherSeasons = _.sortBy (_.filter args.detail, (series) -> series.name != thisSeason.name), (series) -> series.name
					otherSeasons = otherSeasons.reverse()

					content = '<div class="chart-hover-line this-season-base"><b>' + thisSeason.name + '</b>: ' + thisSeason.value.y.toFixed(0) + ' in.</div>'
					_.each otherSeasons, (season) ->
						content += '<div class="chart-hover-line past-season-base"><b>' + season.name + '</b>: ' + season.value.y.toFixed(0) + ' in.</div>'
					
					# pointYValue = _.find args.points, (series) -> series.name = thisSeason.name

					label = document.createElement 'div'
					label.className = 'item active'
					label.innerHTML = content
					label.style.top = graph.y(thisSeason.value.y0 + thisSeason.value.y) + 'px'

					@element.appendChild label

					dot = document.createElement 'div'
					dot.className = 'dot active'
					dot.style.top = label.style.top
					dot.style.borderColor = thisSeason.series.color

					@element.appendChild dot

					@show()

			hover = new Hover graph: graph
		
		populateChartData: () ->
			@paletteStep = -1
			@chartData = []
			@thisSeasonName = _.last((_.keys @dataMap).sort())
			_.each @dataMap, (snowDays, seasonName) =>
				seasonData = []
				_.each snowDays, (snowDay) ->
					seasonData.push
						x: snowDay.season_day
						y: snowDay.base
				@chartData.push 
					name: seasonName
					data: seasonData
					color: @getColor()
					stroke: if seasonName == @thisSeasonName then 'rgba(255,255,255,0.8)' else 'rgba(0,0,0,0.15)'
			@chartData = _.sortBy @chartData, (series) -> series.name

		clickHandler: (model) ->
			#store the model
			@model = model

			#set the name of the clicked resort
			@$('#resort-name').html @model.get 'name'

			callback = (data)=>
				@dataMap = data
				@populateChartData()
				@renderChart()

			requestURI = 'http://snowbase-api.kennychan.co/snow-days/' + @model.get 'name'
			req = new XMLHttpRequest()
			req.addEventListener 'readystatechange', ->
				if req.readyState == 4 #readystate complete
					if req.status == 200 || req.status == 304 #success result codes
						data = eval '(' + req.responseText + ')'
						callback data
					else
						console.log 'Error loading data'
			req.open 'GET', requestURI, false
			req.send()

	class AppView extends Backbone.View
		el: $ '#app'
		initialize: () ->
			Resorts.bind 'sync', @render, this
			Resorts.fetch()
			# SnowDays.fetch()

		appendResort: (resort) ->
			resortView = new ResortView
				model: resort
			@$('#resort-list').append resortView.render().el

		appendAllResorts: () ->
			_.each Resorts.models, (resort) =>
				@appendResort resort

		renderResortDataPane: () ->
			@resortDataPane = new ResortDataPane()

		render: () ->
			@appendAllResorts()
			@renderResortDataPane()

	new AppView()