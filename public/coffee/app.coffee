$ ->
  # console.log 'main script loaded'
  class Resort extends Backbone.Model
    idAttribute: "_id"

  class SnowDay extends Backbone.Model
    idAttribute: "_id"

  class SnowDayCollection extends Backbone.Collection
    model: SnowDay
    url: 'api/snow-days-map'
    initialize: () ->
      @_resortMap = {}
      @on 'sync', @_addAllModelsToMaps
      $.ajax
        url: 'api/snow-days-map'
        success: (data) => 
          @dataMap = data
          console.log data
        dataType: 'json'

    _addModelToMaps: (model) ->
      resortName = model.get 'resort_name'
      date = new Date(model.get 'date')
      season = model.get 'season_name'

      if !@_resortMap[resortName]
        @_resortMap[resortName] = {}
      if !@_resortMap[resortName][season]
        @_resortMap[resortName][season] = {}
      @_resortMap[resortName][season][model.get('date_string') || model.get('season_day')] = model

    _addAllModelsToMaps: () ->
      console.log @models

  class ResortCollection extends Backbone.Collection
    model: Resort
    url: '/api/resorts'
    initialize: ->
      @on 'sync', @populateResortMaps
      @_resortNameMap = {}
      @_resortStateMap = {}
      @_stateInfoMap = {}

    populateResortMaps: () ->
      _.each @models, (model) =>
        state_formatted = model.get 'state_formatted'
        @_resortNameMap[model.get 'formatted_name'] = model
        @_resortStateMap[state_formatted] = {} if !@_resortStateMap[state_formatted]
        @_resortStateMap[state_formatted][model.get 'name'] = model
        @_stateInfoMap[state_formatted] = state_formatted: model.get('state_formatted'), state_short: model.get('state_short')

  # SnowDays = new SnowDayCollection()  
  Resorts = new ResortCollection()
  DataMap = {}
  
  class ResortView extends Backbone.View
    className: 'resort-list-item'
    initialize: ()->
      @fetchQueue = []
    events:
      'click' : 'clickHandler'

    clickHandler: () ->
      $('.resort-list-item-selected').removeClass 'resort-list-item-selected'
      @$el.addClass 'resort-list-item-selected'
      Backbone.Events.trigger 'resortClicked', @model

    render: () ->
      @$el.html @model.get 'formatted_name'
      @

  class ResortDataPane extends Backbone.View
    el: $ '#resort-data-pane'

    events:
      'click #state-picker button' : 'filterStates'

    initialize: ()->
      @chartData = []
      @selectedStates = _.map @$('#state-picker button.active'), (button) -> button.getAttribute('data-state')
      @listenTo Backbone.Events, 'resortClicked', @resortClickedHandler
      @listenTo Backbone.Events, 'compareResortsClicked', @compareResorts
      @paletteStep = -1
      @dateMap = {}
      @rgba = $('html').hasClass 'rgba'
      @basePalette = [
        '#D92929'
        '#F2911B'
        '#016483'
        '#F2CB05'
        '#6ECAC7'
      ]
      @loadingMessageHTML = '<div class="slick-loading-message"><span>L</span><span>O</span><span>A</span><span>D</span><span>I</span><span>N</span><span>G</span></div>'
      @buildColorArrays()
      #Wait to populate data map if data not ready
      if _.size(DataMap) > 0
        @populateDateMap()
        @compareResorts()
      else
        @listenTo Backbone.Events, 'dataMapReturned', () =>
          @populateDateMap()
          @compareResorts()

    filterStates: (e) ->
      $(e.target).toggleClass 'active'
      @selectedStates = _.map @$('#state-picker button.active'), (button) -> button.getAttribute('data-state')

      @populateChartData()
      @renderChart()

    populateDateMap: () ->
      #Push to the date map, so we can match up the "season day" with a date
      seasonToWorkWith = _.find DataMap[Resorts.models[0].get('name')], (seasonData, seasonName) -> seasonName != 'Average'
      _.each seasonToWorkWith, (snowDayData, seasonDay) =>
        dateString = snowDayData.d
        date = new Date(Math.floor(dateString / 10000), Math.floor((dateString / 100) % 100) - 1, Math.floor(dateString % 100))
        @dateMap[seasonDay] = date

    buildColorArrays: () ->
      @paletteHEX = []
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 20)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 45)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 70)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 35)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 60)
      @paletteRGBA = _.map @paletteHEX, (color) => @colorToRGBA(color).rgba

    shadeColor: (color, percent) ->
      num = parseInt(color.slice(1),16)
      amt = Math.round 2.55 * percent
      R = (num >> 16) + amt
      B = (num >> 8 & 0x00FF) + amt
      G = (num & 0x0000FF) + amt
      '#' + (0x1000000 + (if R < 255 then (if R < 1 then 1 else R) else 255)*0x10000 + (if B < 255 then (if B < 1 then 0 else B) else 255) * 0x100 + (if G < 255 then (if G < 1 then 0 else G) else 255)).toString(16).slice(1)

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
      firstSeasonName = @firstSeasonName
      individualResortMode = @individualResortMode
      numSeries = _.size(@chartData) 
      if numSeries == 0
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

      @$('.rickshaw_graph').addClass 'animate-graph'
      #add class to initialize the graph animation

      graph.renderer.unstack = true
      graph.render()

      #Wait for all animations to complete and then rm the animate-graph class so we don't keep animating it when hovering over the legend
      animationCounter = 0
      $('svg g').on 'webkitAnimationEnd', () =>
        animationCounter += 1 
        if animationCounter == numSeries
          setTimeout (() => @$('.rickshaw_graph').removeClass 'animate-graph'), 300

      dateMap = @dateMap
      monthArray = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      dateRenderer = (date) ->
        monthArray[date.getMonth()] + ' ' + date.getDate()


      Hover = Rickshaw.Class.create Rickshaw.Graph.HoverDetail, 
        render: (args) ->
          #if numseries > args.detail.length then we're filtering by hovering on the legend
          showCurrentSeasonDetailHover = if numSeries == args.detail.length then individualResortMode else false
          
          #Get name of this season (the most current one)
          thisSeason = (_.find args.detail, (series) -> series.name == firstSeasonName) || args.detail[0]

          #Get array of other season names
          if showCurrentSeasonDetailHover
            otherSeasons = _.sortBy (_.filter args.detail, (series) -> series.name != thisSeason.name), (series) -> series.name
          else
            otherSeasons = _.sortBy args.detail, (series) -> series.value.y
          otherSeasons = otherSeasons.reverse()

          # set date string to use in hover detail
          dateString = dateRenderer(dateMap[otherSeasons[0].value.x])

          if showCurrentSeasonDetailHover
            # get comparison stats if we're in an individual resort mode
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

          if showCurrentSeasonDetailHover
            #Write this season's base amount in hover label
            content += '<div class="this-season-base">'
            content += '<span class="detail-swatch" style="background-color:' + thisSeason.series.color + '"></span>'
            content += '<b>' + thisSeason.name + '</b>: ' + thisSeason.value.y.toFixed(0) + ' in.'
            if thisSeason.name == maxSeasonName then content += ' <span class="highest-base-label">HIGH</span>'
            if thisSeason.name == minSeasonName then content += ' <span class="lowest-base-label">LOW</span>'
            content += '</div>'
            content += '<div class="this-season-base-comparison-stats">' + baseCompString + '</div>'

          #Write past seasons' base amount in hover label
          _.each otherSeasons, (season) ->
            content += '<div class="past-season-base">'
            if season.name != 'Average'
              content += '<span class="detail-swatch" style="background-color:' + season.series.color + '"></span>'
            content += '<b>' + season.name + '</b>: ' + season.value.y.toFixed(0) + ' in.'

            if showCurrentSeasonDetailHover
              if season.name == maxSeasonName then content += ' <span class="highest-base-label">HIGH</span>'
              if season.name == minSeasonName then content += ' <span class="lowest-base-label">LOW</span>'
            
            content += '</div>'

          dotDataSet = if showCurrentSeasonDetailHover then [thisSeason] else args.detail

          minDotHeight = 1000

          _.each dotDataSet, (data) =>
            dot = document.createElement 'div'
            dot.className = 'dot active'
            dotHeight = graph.y(data.value.y0 + data.value.y)
            minDotHeight = Math.min(minDotHeight, dotHeight)
            dot.style.top = dotHeight + 'px'
            dot.style.borderColor = data.series.color
            @element.appendChild dot

          label = document.createElement 'div'
          label.className = 'item active'
          label.innerHTML = content
          @element.appendChild label
          label.style.top = minDotHeight - Math.max(0, $('.rickshaw_graph').offset().top + minDotHeight + $(label).height() - $(window).height()) + 'px'

          @show()

      hover = new Hover graph: graph

      legend = new Rickshaw.Graph.Legend
        graph: graph
        element: @$('.legend')[0]

      shelving = new Rickshaw.Graph.Behavior.Series.Toggle
        graph: graph
        legend: legend

      highlighter = new Rickshaw.Graph.Behavior.Series.Highlight
        graph: graph
        legend: legend

      xAxis = new Rickshaw.Graph.Axis.X
        graph: graph
        tickFormat: (x) -> dateRenderer(dateMap[x])
      xAxis.render()

      $(window).off 'resize.chart'
      $(window).on 'resize.chart', () => @renderChart()
    
    populateChartData: () ->
      @paletteStep = -1
      @chartData = []
      @averageBaseMap = {}
      @individualResortMode = @model != undefined

      #populate list of selected resorts given selected states
      selectedResorts = []
      _.each @selectedStates, (stateName) ->
        selectedResorts = selectedResorts.concat _.keys Resorts._resortStateMap[stateName]

      seriesNames = if @individualResortMode then (_.keys DataMap[@model.get('name')]).sort().reverse() else _.keys Resorts._resortNameMap

      @firstSeasonName = _.first(_.without(seriesNames, 'Average'))

      dataSet = if @individualResortMode then DataMap[@model.get('name')] else _.pick(DataMap, selectedResorts)

      _.each dataSet, (snowDays, seriesName) =>

        seriesData = []
        seriesSum = 0
        seriesNonZeroDays = 0
        seriesNameToShow = if @individualResortMode then seriesName else _.find(Resorts.models, (resort) -> resort.get('name') == seriesName).get 'formatted_name'

        subDataSet = if @individualResortMode then snowDays else snowDays['Average']

        _.each subDataSet, (snowDayData, seasonDay) =>
          base = snowDayData.b
          dateString = if @individualResortMode then snowDayData.d else 

          #push to seriesData, which we'll use for the chart data
          seriesData.push
            x: parseInt(seasonDay)
            y: base
          
          #calculate total sum so we can get an average
          if base > 0 && seasonDay > 30 && seasonDay < 150 #cut out first and last month in case some resorts don't have as complete data
            seriesSum += base
            seriesNonZeroDays += 1
          # seriesSum += snowDay.get 'base' DOn't know why this is here

        #set average base for each season in the averageBaseMap
        @averageBaseMap[seriesNameToShow] = parseInt(seriesSum / seriesNonZeroDays)

        #Push chart data for Rickshaw
        @chartData.push 
          name: seriesNameToShow
          data: seriesData
          color: '#fff'
          stroke: if seriesName == 'Average' then 'rgba(255,255,255,0.9)' else 'rgba(0,0,0,0.2)'

      #Sort the series first by average, then most recent season, then by average base
      @chartData = _.sortBy @chartData, (series) => 
        if series.name == 'Average' then 0 else if @individualResortMode && series.name == @firstSeasonName then 1 else @averageBaseMap[series.name]
      _.each @chartData, (series) =>
        series.color = if series.name == 'Average' then 'transparent' else @getColor()
      @chartData = @chartData.reverse()


    compareResorts: () ->
      $('.resort-list-item-selected').removeClass 'resort-list-item-selected'
      $('#compare-resorts-link').addClass 'resort-list-item-selected'
      @$('#resort-data').html @loadingMessageHTML
      @$('#resort-name').html 'Average Base Depth (2007-2013)'
      @$('#state-picker').show()
      @model = undefined
      @stopListening Backbone.Events, 'dataMapReturned'

      if _.size(DataMap) == 0
        @listenTo Backbone.Events, 'dataMapReturned', () =>
          @populateChartData
          @renderChart

      @populateChartData()
      @renderChart()

    resortClickedHandler: (model) ->
      #store the model
      @model = model
      @stopListening Backbone.Events, 'dataMapReturned'

      #set the name of the clicked resort
      @$('#resort-name').html @model.get('formatted_name') + ' Base Depth'
      @$('#resort-data').html @loadingMessageHTML
      @$('#state-picker').hide()

      if _.size(DataMap) == 0
        @listenTo Backbone.Events, 'dataMapReturned', () =>
          @populateChartData
          @renderChart

      @populateChartData()
      @renderChart()

  class ResortSearchBox extends Backbone.View
    el: $ '#resort-list-search-box'
    initialize: () ->
      @$el = $ @el
    events: 
      'keyup' : 'filterResults'

    filterResults: () ->
      if @$el.val()
        filter = @$el.val().trim().toUpperCase()
      if filter
        _.each $('.resort-list-item'), (resortItem) ->
          if $(resortItem).text().toUpperCase().indexOf(filter) > -1
            $(resortItem).removeClass 'slide-down'
          else
            $(resortItem).addClass 'slide-down'
      else
        $('.resort-list-item').removeClass 'slide-down'

  class AppView extends Backbone.View
    el: $ '#app'
    events: 
      'click #compare-resorts-link' : 'compareResortsClickHandler'

    initialize: () ->
      Resorts.bind 'sync', @render, this
      Resorts.fetch()
      #Get snowday map
      $.ajax
        url: 'api/snow-days-map'
        success: (data) => 
          DataMap = data
          Backbone.Events.trigger 'dataMapReturned'
        dataType: 'json'
      #Delay fetching all snowdays
      # setTimeout (() -> SnowDays.fetch()), 3000
    
    compareResortsClickHandler: () ->
      Backbone.Events.trigger 'compareResortsClicked'

    appendResort: (resort) ->
      resortView = new ResortView
        model: resort
      @$('#resort-list').append resortView.render().el

    appendAllResorts: () ->
      sortedStateList = _.sortBy Resorts._resortStateMap, (v, k) -> k
      stateNames = _.keys(Resorts._resortStateMap).sort()

      _.each sortedStateList, (resorts, index) =>

        stateName = stateNames[index]
        stateAbbrev = Resorts._stateInfoMap[stateName]['state_short']

        #append state header to resort list
        @$('#resort-list').append '<div class="resort-list-state-header">' + stateName + '</div>'

        #append button to state picker
        $('#state-picker').append '<button data-state="' + stateName + '" class="btn btn-primary active">' + stateAbbrev + '</button>'

        sortedResortList = _.sortBy resorts, (v, k) -> k
        _.each sortedResortList, (resort) =>
          @appendResort resort

    renderResortDataPane: () ->
      @resortDataPane = new ResortDataPane()

    initResortSearchBox: () ->
      @resortSearchBox = new ResortSearchBox()

    render: () ->
      @appendAllResorts()
      @initResortSearchBox()
      @renderResortDataPane()

  new AppView()