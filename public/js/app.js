(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var AppView, Resort, ResortCollection, ResortDataPane, ResortView, Resorts, SnowDay, SnowDayCollection, SnowDays, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;

    Resort = (function(_super) {
      __extends(Resort, _super);

      function Resort() {
        _ref = Resort.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Resort.prototype.idAttribute = "_id";

      return Resort;

    })(Backbone.Model);
    SnowDay = (function(_super) {
      __extends(SnowDay, _super);

      function SnowDay() {
        _ref1 = SnowDay.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      SnowDay.prototype.idAttribute = "_id";

      return SnowDay;

    })(Backbone.Model);
    SnowDayCollection = (function(_super) {
      __extends(SnowDayCollection, _super);

      function SnowDayCollection() {
        _ref2 = SnowDayCollection.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      SnowDayCollection.prototype.model = SnowDay;

      SnowDayCollection.prototype.url = 'api/snow-days';

      SnowDayCollection.prototype.initialize = function() {
        this._resortMap = {};
        this.on('add', this._addModelToMaps);
        return this.on('sync', this._addAllModelsToMaps);
      };

      SnowDayCollection.prototype._addModelToMaps = function(model) {
        var date, resortName, season;

        resortName = model.get('resort_name');
        date = new Date(model.get('date'));
        season = model.get('season_name');
        if (!this._resortMap[resortName]) {
          this._resortMap[resortName] = {};
        }
        if (!this._resortMap[resortName][season]) {
          this._resortMap[resortName][season] = {};
        }
        return this._resortMap[resortName][season][model.get('date_string')] = model;
      };

      SnowDayCollection.prototype._addAllModelsToMaps = function() {
        var _this = this;

        this._resortMap = {};
        return _.each(this.models, function(model) {
          return _this._addModelToMaps(model);
        });
      };

      return SnowDayCollection;

    })(Backbone.Collection);
    ResortCollection = (function(_super) {
      __extends(ResortCollection, _super);

      function ResortCollection() {
        _ref3 = ResortCollection.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      ResortCollection.prototype.model = Resort;

      ResortCollection.prototype.url = '/api/resorts';

      return ResortCollection;

    })(Backbone.Collection);
    SnowDays = new SnowDayCollection();
    Resorts = new ResortCollection();
    ResortView = (function(_super) {
      __extends(ResortView, _super);

      function ResortView() {
        _ref4 = ResortView.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      ResortView.prototype.className = 'resort-list-item';

      ResortView.prototype.events = {
        'click': 'clickHandler'
      };

      ResortView.prototype.clickHandler = function() {
        return Backbone.Events.trigger('resortClicked', this.model);
      };

      ResortView.prototype.render = function() {
        this.$el.html(this.model.get('formatted_name'));
        return this;
      };

      return ResortView;

    })(Backbone.View);
    ResortDataPane = (function(_super) {
      __extends(ResortDataPane, _super);

      function ResortDataPane() {
        _ref5 = ResortDataPane.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      ResortDataPane.prototype.el = $('#resort-data-pane');

      ResortDataPane.prototype.initialize = function() {
        var _this = this;

        this.chartData = [];
        this.listenTo(Backbone.Events, 'resortClicked', this.clickHandler);
        this.paletteStep = -1;
        this.rgba = $('html').hasClass('rgba');
        this.paletteHEX = ['#39cc67', '#70A5FF', '#85B1FF', '#99BEFF', '#ADCBFF', '#C2D8FF', '#D6E5FF', '#EBF2FF'];
        return this.paletteRGBA = _.map(this.paletteHEX, function(color) {
          return _this.colorToRGBA(color).rgba;
        });
      };

      ResortDataPane.prototype.colorToRGBA = function(r, g, b) {
        var a, min;

        if (g === void 0 && typeof r === 'string') {
          r = r.replace(/^\s*#|\s*$/g, '');
          if (r.length === 3) {
            r.replace(/(.)/g, '$1$1');
          }
          g = parseInt(r.substr(2, 2), 16);
          b = parseInt(r.substr(4, 2), 16);
          r = parseInt(r.substr(0, 2), 16);
          min = Math.min(r, g, b);
          a = (255 - min) / 255;
          return {
            r: r = 0 | (r - min) / a,
            g: g = 0 | (g - min) / a,
            b: b = 0 | (b - min) / a,
            a: a = (0 | 1000 * a) / 1000,
            rgba: 'rgba(' + r + ', ' + g + ', ' + b + ', ' + a + ')'
          };
        }
      };

      ResortDataPane.prototype.getColor = function() {
        this.paletteStep += 1;
        if (this.rgba) {
          return this.paletteRGBA[this.paletteStep] || this.paletteRGBA[this.paletteRGBA.length - 1];
        } else {
          return this.paletteHEX[this.paletteStep] || this.paletteHEX[this.paletteHEX.length - 1];
        }
      };

      ResortDataPane.prototype.renderChart = function() {
        var Hover, chartHeight, chartWidth, dateMap, graph, highlighter, hover, legend, monthArray, shelving,
          _this = this;

        this.$('.rickshaw_graph, .legend, .chart-slider').remove();
        this.$('#resort-data').html('<div class="rickshaw_graph"></div><div class="legend"></div><div class="chart-slider"></div>');
        chartWidth = ($(window).width() * (.829 - .0256)) - 40;
        chartHeight = Math.min(500, $(window).height() - 90);
        if (_.size(this.chartData) === 0) {
          return;
        }
        graph = new Rickshaw.Graph({
          element: this.$('.rickshaw_graph')[0],
          width: chartWidth,
          height: chartHeight,
          stroke: true,
          renderer: this.rgba ? 'area' : 'line',
          series: this.chartData,
          interpolation: 'basis'
        });
        graph.renderer.unstack = true;
        graph.render();
        this.$('.rickshaw_graph').addClass('come-in');
        legend = new Rickshaw.Graph.Legend({
          graph: graph,
          element: this.$('.legend')[0]
        });
        shelving = new Rickshaw.Graph.Behavior.Series.Toggle({
          graph: graph,
          legend: legend
        });
        highlighter = new Rickshaw.Graph.Behavior.Series.Highlight({
          graph: graph,
          legend: legend
        });
        dateMap = this.dateMap;
        monthArray = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        Hover = Rickshaw.Class.create(Rickshaw.Graph.HoverDetail, {
          render: function(args) {
            var baseAvg, baseCompPercentage, baseCompString, content, date, dateString, dot, dotHeight, label, maxBase, maxSeasonName, minBase, minSeasonName, otherSeasons, thisSeason;

            thisSeason = _.last(_.sortBy(args.detail, function(series) {
              return series.name;
            }));
            otherSeasons = _.sortBy(_.filter(args.detail, function(series) {
              return series.name !== thisSeason.name;
            }), function(series) {
              return series.name;
            });
            otherSeasons = otherSeasons.reverse();
            date = new Date(dateMap[thisSeason.value.x]);
            dateString = monthArray[date.getMonth()] + ' ' + date.getDate();
            maxBase = 0;
            minBase = 9999;
            maxSeasonName = '';
            minSeasonName = '';
            baseAvg = 0;
            _.each(args.detail, function(series) {
              baseAvg += series.value.y;
              if (series.value.y > maxBase) {
                maxSeasonName = series.name;
                maxBase = series.value.y;
              }
              if (series.value.y < minBase) {
                minSeasonName = series.name;
                return minBase = series.value.y;
              }
            });
            baseAvg = baseAvg / args.detail.length;
            baseCompPercentage = ((thisSeason.value.y / baseAvg) - 1) * 100;
            baseCompString = Math.abs(baseCompPercentage.toFixed(0)) + '% <span class="base-comparison-above-below">' + (baseCompPercentage < 0 ? 'below' : 'above') + '</span> average';
            content = '<div class="chart-hover-date">' + dateString + ' Base Depth</div>';
            content += '<div class="this-season-base"><b>' + thisSeason.name + '</b>: ' + thisSeason.value.y.toFixed(0) + ' in.';
            if (thisSeason.name === maxSeasonName) {
              content += ' <span class="highest-base-label">HIGH</span>';
            }
            if (thisSeason.name === minSeasonName) {
              content += ' <span class="lowest-base-label">LOW</span>';
            }
            content += '</div>';
            content += '<div class="this-season-base-comparison-stats">' + baseCompString + '</div>';
            _.each(otherSeasons, function(season) {
              content += '<div class="past-season-base"><b>' + season.name + '</b>: ' + season.value.y.toFixed(0) + ' in.';
              if (season.name === maxSeasonName) {
                content += ' <span class="highest-base-label">HIGH</span>';
              }
              if (season.name === minSeasonName) {
                content += ' <span class="lowest-base-label">LOW</span>';
              }
              return content += '</div>';
            });
            dot = document.createElement('div');
            dot.className = 'dot active';
            dotHeight = graph.y(thisSeason.value.y0 + thisSeason.value.y);
            dot.style.top = dotHeight + 'px';
            dot.style.borderColor = thisSeason.series.color;
            this.element.appendChild(dot);
            label = document.createElement('div');
            label.className = 'item active';
            label.innerHTML = content;
            this.element.appendChild(label);
            label.style.top = dotHeight - Math.max(0, $('.rickshaw_graph').offset().top + dotHeight + $(label).height() - $(window).height()) + 'px';
            return this.show();
          }
        });
        hover = new Hover({
          graph: graph
        });
        $(window).off('resize.chart');
        return $(window).on('resize.chart', function() {
          return _this.renderChart();
        });
      };

      ResortDataPane.prototype.populateChartData = function() {
        var colorMap, seasonNames,
          _this = this;

        this.paletteStep = -1;
        this.chartData = [];
        this.dateMap = {};
        seasonNames = (_.keys(SnowDays._resortMap[this.model.get('name')])).sort().reverse();
        colorMap = {};
        _.each(seasonNames, function(seasonName) {
          return colorMap[seasonName] = _this.getColor();
        });
        this.thisSeasonName = _.first(seasonNames);
        _.each(SnowDays._resortMap[this.model.get('name')], function(snowDays, seasonName) {
          var seasonData;

          seasonData = [];
          _.each(snowDays, function(snowDay) {
            seasonData.push({
              x: snowDay.get('season_day'),
              y: snowDay.get('base')
            });
            return _this.dateMap[snowDay.get('season_day')] = snowDay.get('date');
          });
          return _this.chartData.push({
            name: seasonName,
            data: seasonData,
            color: colorMap[seasonName],
            stroke: seasonName === _this.thisSeasonName ? 'rgba(255,255,255,0.8)' : 'rgba(0,0,0,0.25)'
          });
        });
        return this.chartData = _.sortBy(this.chartData, function(series) {
          return series.name;
        });
      };

      ResortDataPane.prototype.clickHandler = function(model) {
        var _this = this;

        this.model = model;
        this.$('#resort-name').html(this.model.get('formatted_name') + ' Base Depth');
        this.$('#resort-data').html('<div class="slick-loading-message"><span>L</span><span>O</span><span>A</span><span>D</span><span>I</span><span>N</span><span>G</span></div>');
        if (SnowDays.models.length === 0) {
          this.listenTo(SnowDays, 'sync', function() {
            _this.populateChartData();
            return _this.renderChart();
          });
          return;
        }
        this.stopListening(SnowDays, 'sync');
        this.populateChartData();
        return this.renderChart();
      };

      return ResortDataPane;

    })(Backbone.View);
    AppView = (function(_super) {
      __extends(AppView, _super);

      function AppView() {
        _ref6 = AppView.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      AppView.prototype.el = $('#app');

      AppView.prototype.initialize = function() {
        Resorts.bind('sync', this.render, this);
        Resorts.fetch();
        return SnowDays.fetch();
      };

      AppView.prototype.appendResort = function(resort) {
        var resortView;

        resortView = new ResortView({
          model: resort
        });
        return this.$('#resort-list').append(resortView.render().el);
      };

      AppView.prototype.appendAllResorts = function() {
        var _this = this;

        return _.each(Resorts.models, function(resort) {
          return _this.appendResort(resort);
        });
      };

      AppView.prototype.renderResortDataPane = function() {
        return this.resortDataPane = new ResortDataPane();
      };

      AppView.prototype.render = function() {
        this.appendAllResorts();
        return this.renderResortDataPane();
      };

      return AppView;

    })(Backbone.View);
    return new AppView();
  });

}).call(this);
