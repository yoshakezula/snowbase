$ ->
	console.log 'main script loaded'
	class Resort extends Backbone.Model
		idAttribute: "_id"

	class SnowDay extends Backbone.Model
		idAttribute: "_id"

	class SnowDayCollection extends Backbone.Collection
		model: SnowDay
		url: 'api/snow-days'
		initialize: () ->
			@_resortMap = {}
			@on 'add', @_addModelToMaps
			@on 'sync', @_addAllModelsToMaps

		_addModelToMaps: (model) ->
			resortName = model.get 'resort_name'
			date = new Date(model.get 'date')
			season = model.get 'season_name'

			if !@_resortMap[resortName]
				@_resortMap[resortName] = {}
			if !@_resortMap[resortName][season]
				@_resortMap[resortName][season] = {}
			@_resortMap[resortName][season][model.get 'date_string'] = model

		_addAllModelsToMaps: () ->
			@_resortMap = {}
			_.each @models, (model) =>
				@_addModelToMaps model

	class ResortCollection extends Backbone.Collection
		model: Resort
		url: '/api/resorts'

	SnowDays = new SnowDayCollection()	
	Resorts = new ResortCollection()
	
	class ResortView extends Backbone.View
		className: 'resort-list-item'
		events:
			'click' : 'clickHandler'

		clickHandler: () ->
			Backbone.Events.trigger 'resortClicked', @model

		render: () ->
			@$el.html @model.get 'formatted_name'
			@

	class ResortDataPane extends Backbone.View
		el: $ '#resort-data-pane'
		initialize: ()->
			@chartData = []
			@listenTo Backbone.Events, 'resortClicked', @clickHandler
			@paletteStep = -1
			@rgba = $('html').hasClass 'rgba'
			@paletteHEX = [
				'#39cc67' #aqua
				# '#C6E774' #green
				# '#337EFF' #blue
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
			chartHeight = Math.min(500, $(window).height() - 90)
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
			@$('.rickshaw_graph').addClass 'come-in'

			legend = new Rickshaw.Graph.Legend
				graph: graph
				element: @$('.legend')[0]

			shelving = new Rickshaw.Graph.Behavior.Series.Toggle
				graph: graph
				legend: legend

			highlighter = new Rickshaw.Graph.Behavior.Series.Highlight
				graph: graph
				legend: legend

			dateMap = @dateMap
			monthArray = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
			Hover = Rickshaw.Class.create Rickshaw.Graph.HoverDetail, 
				render: (args) ->
					#Get name of this season (the most current one)
					thisSeason = _.last _.sortBy(args.detail, (series) -> series.name)

					#Get array of other season names
					otherSeasons = _.sortBy (_.filter args.detail, (series) -> series.name != thisSeason.name), (series) -> series.name
					otherSeasons = otherSeasons.reverse()

					# set date string to use in hover detail
					date = new Date(dateMap[thisSeason.value.x])
					dateString = monthArray[date.getMonth()] + ' ' + date.getDate()

					# get comparison stats
					maxBase = 0
					minBase = 9999
					maxSeasonName = ''
					minSeasonName = ''
					baseAvg = 0
					_.each args.detail, (series) ->
						baseAvg += series.value.y
						if series.value.y > maxBase
							maxSeasonName = series.name
							maxBase = series.value.y
						if series.value.y < minBase
							minSeasonName = series.name
							minBase = series.value.y

					baseAvg = baseAvg / args.detail.length
					baseCompPercentage = ((thisSeason.value.y / baseAvg) - 1) * 100
					baseCompString = Math.abs(baseCompPercentage.toFixed(0)) + '% <span class="base-comparison-above-below">' + (if baseCompPercentage < 0 then 'below' else 'above') + '</span> average'

					# Write date on hover label
					content = '<div class="chart-hover-date">' + dateString + ' Base Depth</div>'

					#Write this season's base amount in hover label
					content += '<div class="this-season-base"><b>' + thisSeason.name + '</b>: ' + thisSeason.value.y.toFixed(0) + ' in.'
					if thisSeason.name == maxSeasonName then content += ' <span class="highest-base-label">HIGH</span>'
					if thisSeason.name == minSeasonName then content += ' <span class="lowest-base-label">LOW</span>'
					content += '</div>'
					content += '<div class="this-season-base-comparison-stats">' + baseCompString + '</div>'

					#Write past seasons' base amount in hover label
					_.each otherSeasons, (season) ->
						content += '<div class="past-season-base"><b>' + season.name + '</b>: ' + season.value.y.toFixed(0) + ' in.'
						if season.name == maxSeasonName then content += ' <span class="highest-base-label">HIGH</span>'
						if season.name == minSeasonName then content += ' <span class="lowest-base-label">LOW</span>'
						content += '</div>'

					dot = document.createElement 'div'
					dot.className = 'dot active'
					dotHeight = graph.y(thisSeason.value.y0 + thisSeason.value.y)
					dot.style.top = dotHeight + 'px'
					dot.style.borderColor = thisSeason.series.color
					@element.appendChild dot

					label = document.createElement 'div'
					label.className = 'item active'
					label.innerHTML = content
					@element.appendChild label
					label.style.top = dotHeight - Math.max(0, $('.rickshaw_graph').offset().top + dotHeight + $(label).height() - $(window).height()) + 'px'

					# xLabel = document.createElement 'div'
					# xLabel.className = 'x_label'
					# xLabel.innerHTML = monthArray[date.getMonth()] + ' ' + date.getDate()
					# xLabel.style.top = dotHeight + 'px'
					# @element.appendChild xLabel

					@show()

			hover = new Hover graph: graph
			$(window).off 'resize.chart'
			$(window).on 'resize.chart', () => @renderChart()
		
		populateChartData: () ->
			@paletteStep = -1
			@chartData = []
			@dateMap = {}

			seasonNames = (_.keys SnowDays._resortMap[@model.get('name')]).sort().reverse()
			colorMap = {}
			_.each seasonNames, (seasonName) =>
				colorMap[seasonName] = @getColor()
			@thisSeasonName = _.first(seasonNames)
			_.each SnowDays._resortMap[@model.get('name')], (snowDays, seasonName) =>
				seasonData = []
				_.each snowDays, (snowDay) =>
					#push to seasonData, which we'll use for the chart data
					seasonData.push
						x: snowDay.get 'season_day'
						y: snowDay.get 'base'
					
					#Push to the date map, so we can match up the "season day" with a date
					@dateMap[snowDay.get 'season_day'] = snowDay.get('date')

				@chartData.push 
					name: seasonName
					data: seasonData
					color: colorMap[seasonName]
					stroke: if seasonName == @thisSeasonName then 'rgba(255,255,255,0.8)' else 'rgba(0,0,0,0.25)'
			@chartData = _.sortBy @chartData, (series) -> series.name

		clickHandler: (model) ->
			#store the model
			@model = model

			#set the name of the clicked resort
			@$('#resort-name').html @model.get('formatted_name') + ' Base Depth'

			@$('#resort-data').html '<div class="slick-loading-message"><span>L</span><span>O</span><span>A</span><span>D</span><span>I</span><span>N</span><span>G</span></div>'

			#Make sure the chart data is ready
			if SnowDays.models.length == 0
				@listenTo SnowDays, 'sync', () => 
					@populateChartData()
					@renderChart()
				return
			@stopListening SnowDays, 'sync'

			@populateChartData()
			@renderChart()

	class AppView extends Backbone.View
		el: $ '#app'
		initialize: () ->
			Resorts.bind 'sync', @render, this
			Resorts.fetch()
			SnowDays.fetch()

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