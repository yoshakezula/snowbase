$ ->
  # console.log 'main script loaded'
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
      @_resortMap[resortName][season][model.get('date_string') || model.get('season_day')] = model

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
      if !SnowDays._resortMap[@model.get 'name']
        SnowDays.fetch data: resort_id: @model.id
      $('.resort-list-item-selected').removeClass 'resort-list-item-selected'
      @$el.addClass 'resort-list-item-selected'
      Backbone.Events.trigger 'resortClicked', @model

    render: () ->
      @$el.html @model.get 'formatted_name'
      @

  class ResortDataPane extends Backbone.View
    el: $ '#resort-data-pane'
    initialize: ()->
      @chartData = []
      @listenTo Backbone.Events, 'resortClicked', @resortClickedHandler
      @listenTo Backbone.Events, 'compareResortsClicked', @compareResorts
      @paletteStep = -1
      @rgba = $('html').hasClass 'rgba'
      @basePalette = [
        '#D92929'
        '#F2911B'
        '#016483'
        '#F2CB05'
        '#6ECAC7'
        # '#BF4B31'
        # '#FCC240'
        # '#BF4B31'
        # '#4D8B4D'
        # '#4B3929'
      ]
      @loadingMessageHTML = '<div class="slick-loading-message"><span>L</span><span>O</span><span>A</span><span>D</span><span>I</span><span>N</span><span>G</span></div>'
      @buildColorArrays()

    buildColorArrays: () ->
      @paletteHEX = []
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 20)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 45)
      _.each @basePalette, (color) =>
        @paletteHEX.push @shadeColor(color, 70)
      # @paletteHEX = [
      #   '#39cc67' #aqua
      #   '#70A5FF'
      #   '#85B1FF'
      #   '#99BEFF'
      #   '#ADCBFF'
      #   '#C2D8FF'
      #   '#D6E5FF'
      #   '#EBF2FF'
      # ]
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

      Hover = Rickshaw.Class.create Rickshaw.Graph.HoverDetail, 
        render: (args) ->
          #Get name of this season (the most current one)
          thisSeason = (_.find args.detail, (series) -> series.name == firstSeasonName) || {name: 'franz'}

          #Get array of other season names
          if individualResortMode
            otherSeasons = _.sortBy (_.filter args.detail, (series) -> series.name != thisSeason.name), (series) -> series.name
          else
            otherSeasons = _.sortBy args.detail, (series) -> series.value.y
          otherSeasons = otherSeasons.reverse()

          # set date string to use in hover detail
          date = new Date(dateMap[otherSeasons[0].value.x])
          dateString = monthArray[date.getMonth()] + ' ' + date.getDate()

          if individualResortMode
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

          if individualResortMode
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

            if individualResortMode
              if season.name == maxSeasonName then content += ' <span class="highest-base-label">HIGH</span>'
              if season.name == minSeasonName then content += ' <span class="lowest-base-label">LOW</span>'
            
            content += '</div>'

          dotDataSet = if individualResortMode then [thisSeason] else args.detail

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

          # xLabel = document.createElement 'div'
          # xLabel.className = 'x_label'
          # xLabel.innerHTML = monthArray[date.getMonth()] + ' ' + date.getDate()
          # xLabel.style.top = dotHeight + 'px'
          # @element.appendChild xLabel

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

      dateMap = @dateMap
      monthArray = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      $(window).off 'resize.chart'
      $(window).on 'resize.chart', () => @renderChart()
    
    populateChartData: () ->
      @paletteStep = -1
      @chartData = []
      @dateMap = {}
      @averageBaseMap = {}
      @individualResortMode = @model != undefined

      seriesNames = if @individualResortMode then (_.keys SnowDays._resortMap[@model.get('name')]).sort().reverse() else _.keys SnowDays._resortMap
      colorMap = {}
      _.each seriesNames, (seriesName) =>
        colorMap[seriesName] = if seriesName == 'Average' then 'transparent' else @getColor()

      @firstSeasonName = _.first(_.without(seriesNames, 'Average'))

      dataSet = if @individualResortMode then SnowDays._resortMap[@model.get('name')] else SnowDays._resortMap

      _.each dataSet, (snowDays, seriesName) =>

        seriesData = []
        seriesSum = 0
        seriesNonZeroDays = 0
        seriesNameToShow = if @individualResortMode then seriesName else _.find(Resorts.models, (resort) -> resort.get('name') == seriesName).get 'formatted_name'

        subDataSet = if @individualResortMode then snowDays else snowDays['Average']

        _.each subDataSet, (snowDay) =>
          base = snowDay.get 'base'
          seasonDay = snowDay.get 'season_day'

          #push to seriesData, which we'll use for the chart data
          seriesData.push
            x: seasonDay
            y: base
          
          #calculate total sum so we can get an average
          if base > 0 && seasonDay > 30 && seasonDay < 150 #cut out first and last month in case some resorts don't have as complete data
            seriesSum += base
            seriesNonZeroDays += 1
          seriesSum += snowDay.get 'base'

          #Push to the date map, so we can match up the "season day" with a date
          @dateMap[seasonDay] = snowDay.get('date')

        #set average base for each season in the averageBaseMap
        @averageBaseMap[seriesNameToShow] = parseInt(seriesSum / seriesNonZeroDays)

        #Push chart data for Rickshaw
        @chartData.push 
          name: seriesNameToShow
          data: seriesData
          color: colorMap[seriesName]
          stroke: if seriesName == 'Average' then 'rgba(255,255,255,0.9)' else 'rgba(0,0,0,0.2)'

      #Sort the series first by average, then most recent season, then by average base
      @chartData = _.sortBy @chartData, (series) => 
        if series.name == 'Average' then 0 else if @individualResortMode && series.name == @firstSeasonName then 1 else @averageBaseMap[series.name]
      @chartData = @chartData.reverse()


    compareResorts: () ->
      $('.resort-list-item-selected').removeClass 'resort-list-item-selected'
      $('#compare-resorts-link').addClass 'resort-list-item-selected'
      @$('#resort-data').html @loadingMessageHTML
      @$('#resort-name').html 'Comparative Base Depth'
      @model = undefined

      #Make sure the chart data is ready
      if _.size(SnowDays._resortMap) == 0
        @listenTo SnowDays, 'sync', () => 
          @populateChartData()
          @renderChart()
        return
      @stopListening SnowDays, 'sync'

      @populateChartData()
      @renderChart()

    resortClickedHandler: (model) ->
      #store the model
      @model = model

      #set the name of the clicked resort
      @$('#resort-name').html @model.get('formatted_name') + ' Base Depth'

      @$('#resort-data').html @loadingMessageHTML

      #Make sure the chart data is ready
      if !SnowDays._resortMap[@model.get 'name']
        @listenTo SnowDays, 'sync', () => 
          @populateChartData()
          @renderChart()
        return
      @stopListening SnowDays, 'sync'

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
      #Delay fetching all snowdays
      setTimeout (() -> SnowDays.fetch()), 3000
    
    compareResortsClickHandler: () ->
      Backbone.Events.trigger 'compareResortsClicked'

    appendResort: (resort) ->
      resortView = new ResortView
        model: resort
      @$('#resort-list').append resortView.render().el

    appendAllResorts: () ->
      sortedResortList = _.sortBy Resorts.models, (resort) ->
        resort.get 'formatted_name'
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