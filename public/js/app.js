(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var AppView, Resort, ResortCollection, ResortDataPane, ResortSearchBox, ResortView, Resorts, SnowDay, SnowDayCollection, SnowDays, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;

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
        return this._resortMap[resortName][season][model.get('date_string') || model.get('season_day')] = model;
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
        if (!SnowDays._resortMap[this.model.get('name')]) {
          SnowDays.fetch({
            data: {
              resort_id: this.model.id
            }
          });
        }
        $('.resort-list-item-selected').removeClass('resort-list-item-selected');
        this.$el.addClass('resort-list-item-selected');
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
        this.chartData = [];
        this.listenTo(Backbone.Events, 'resortClicked', this.resortClickedHandler);
        this.listenTo(Backbone.Events, 'compareResortsClicked', this.compareResorts);
        this.paletteStep = -1;
        this.rgba = $('html').hasClass('rgba');
        this.basePalette = ['#D92929', '#F2911B', '#016483', '#F2CB05', '#6ECAC7'];
        this.loadingMessageHTML = '<div class="slick-loading-message"><span>L</span><span>O</span><span>A</span><span>D</span><span>I</span><span>N</span><span>G</span></div>';
        return this.buildColorArrays();
      };

      ResortDataPane.prototype.buildColorArrays = function() {
        var _this = this;

        this.paletteHEX = [];
        _.each(this.basePalette, function(color) {
          return _this.paletteHEX.push(_this.shadeColor(color, 20));
        });
        _.each(this.basePalette, function(color) {
          return _this.paletteHEX.push(_this.shadeColor(color, 45));
        });
        _.each(this.basePalette, function(color) {
          return _this.paletteHEX.push(_this.shadeColor(color, 70));
        });
        return this.paletteRGBA = _.map(this.paletteHEX, function(color) {
          return _this.colorToRGBA(color).rgba;
        });
      };

      ResortDataPane.prototype.shadeColor = function(color, percent) {
        var B, G, R, amt, num;

        num = parseInt(color.slice(1), 16);
        amt = Math.round(2.55 * percent);
        R = (num >> 16) + amt;
        B = (num >> 8 & 0x00FF) + amt;
        G = (num & 0x0000FF) + amt;
        return '#' + (0x1000000 + (R < 255 ? (R < 1 ? 1 : R) : 255) * 0x10000 + (B < 255 ? (B < 1 ? 0 : B) : 255) * 0x100 + (G < 255 ? (G < 1 ? 0 : G) : 255)).toString(16).slice(1);
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
        var Hover, chartHeight, chartWidth, dateMap, firstSeasonName, graph, highlighter, hover, individualResortMode, legend, monthArray, shelving,
          _this = this;

        this.$('.rickshaw_graph, .legend, .chart-slider').remove();
        this.$('#resort-data').html('<div class="rickshaw_graph"></div><div class="legend"></div><div class="chart-slider"></div>');
        chartWidth = ($(window).width() * (.829 - .0256)) - 40;
        chartHeight = Math.min(500, $(window).height() - 90);
        firstSeasonName = this.firstSeasonName;
        individualResortMode = this.individualResortMode;
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
        Hover = Rickshaw.Class.create(Rickshaw.Graph.HoverDetail, {
          render: function(args) {
            var baseAvg, baseCompPercentage, baseCompString, content, date, dateString, dotDataSet, label, maxBase, maxSeasonName, minBase, minDotHeight, minSeasonName, otherSeasons, thisSeason,
              _this = this;

            thisSeason = (_.find(args.detail, function(series) {
              return series.name === firstSeasonName;
            })) || {
              name: 'franz'
            };
            if (individualResortMode) {
              otherSeasons = _.sortBy(_.filter(args.detail, function(series) {
                return series.name !== thisSeason.name;
              }), function(series) {
                return series.name;
              });
            } else {
              otherSeasons = _.sortBy(args.detail, function(series) {
                return series.value.y;
              });
            }
            otherSeasons = otherSeasons.reverse();
            date = new Date(dateMap[otherSeasons[0].value.x]);
            dateString = monthArray[date.getMonth()] + ' ' + date.getDate();
            if (individualResortMode) {
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
            }
            content = '<div class="chart-hover-date">' + dateString + ' Base Depth</div>';
            if (individualResortMode) {
              content += '<div class="this-season-base">';
              content += '<span class="detail-swatch" style="background-color:' + thisSeason.series.color + '"></span>';
              content += '<b>' + thisSeason.name + '</b>: ' + thisSeason.value.y.toFixed(0) + ' in.';
              if (thisSeason.name === maxSeasonName) {
                content += ' <span class="highest-base-label">HIGH</span>';
              }
              if (thisSeason.name === minSeasonName) {
                content += ' <span class="lowest-base-label">LOW</span>';
              }
              content += '</div>';
              content += '<div class="this-season-base-comparison-stats">' + baseCompString + '</div>';
            }
            _.each(otherSeasons, function(season) {
              content += '<div class="past-season-base">';
              if (season.name !== 'Average') {
                content += '<span class="detail-swatch" style="background-color:' + season.series.color + '"></span>';
              }
              content += '<b>' + season.name + '</b>: ' + season.value.y.toFixed(0) + ' in.';
              if (individualResortMode) {
                if (season.name === maxSeasonName) {
                  content += ' <span class="highest-base-label">HIGH</span>';
                }
                if (season.name === minSeasonName) {
                  content += ' <span class="lowest-base-label">LOW</span>';
                }
              }
              return content += '</div>';
            });
            dotDataSet = individualResortMode ? [thisSeason] : args.detail;
            minDotHeight = 1000;
            _.each(dotDataSet, function(data) {
              var dot, dotHeight;

              dot = document.createElement('div');
              dot.className = 'dot active';
              dotHeight = graph.y(data.value.y0 + data.value.y);
              minDotHeight = Math.min(minDotHeight, dotHeight);
              dot.style.top = dotHeight + 'px';
              dot.style.borderColor = data.series.color;
              return _this.element.appendChild(dot);
            });
            label = document.createElement('div');
            label.className = 'item active';
            label.innerHTML = content;
            this.element.appendChild(label);
            label.style.top = minDotHeight - Math.max(0, $('.rickshaw_graph').offset().top + minDotHeight + $(label).height() - $(window).height()) + 'px';
            return this.show();
          }
        });
        hover = new Hover({
          graph: graph
        });
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
        $(window).off('resize.chart');
        return $(window).on('resize.chart', function() {
          return _this.renderChart();
        });
      };

      ResortDataPane.prototype.populateChartData = function() {
        var colorMap, dataSet, seriesNames,
          _this = this;

        this.paletteStep = -1;
        this.chartData = [];
        this.dateMap = {};
        this.averageBaseMap = {};
        this.individualResortMode = this.model !== void 0;
        seriesNames = this.individualResortMode ? (_.keys(SnowDays._resortMap[this.model.get('name')])).sort().reverse() : _.keys(SnowDays._resortMap);
        colorMap = {};
        _.each(seriesNames, function(seriesName) {
          return colorMap[seriesName] = seriesName === 'Average' ? 'transparent' : _this.getColor();
        });
        this.firstSeasonName = _.first(_.without(seriesNames, 'Average'));
        dataSet = this.individualResortMode ? SnowDays._resortMap[this.model.get('name')] : SnowDays._resortMap;
        _.each(dataSet, function(snowDays, seriesName) {
          var seriesData, seriesNameToShow, seriesNonZeroDays, seriesSum, subDataSet;

          seriesData = [];
          seriesSum = 0;
          seriesNonZeroDays = 0;
          seriesNameToShow = _this.individualResortMode ? seriesName : _.find(Resorts.models, function(resort) {
            return resort.get('name') === seriesName;
          }).get('formatted_name');
          subDataSet = _this.individualResortMode ? snowDays : snowDays['Average'];
          _.each(subDataSet, function(snowDay) {
            var base, seasonDay;

            base = snowDay.get('base');
            seasonDay = snowDay.get('season_day');
            seriesData.push({
              x: seasonDay,
              y: base
            });
            if (base > 0 && seasonDay > 30 && seasonDay < 150) {
              seriesSum += base;
              seriesNonZeroDays += 1;
            }
            seriesSum += snowDay.get('base');
            return _this.dateMap[seasonDay] = snowDay.get('date');
          });
          _this.averageBaseMap[seriesNameToShow] = parseInt(seriesSum / seriesNonZeroDays);
          return _this.chartData.push({
            name: seriesNameToShow,
            data: seriesData,
            color: colorMap[seriesName],
            stroke: seriesName === 'Average' ? 'rgba(255,255,255,0.9)' : 'rgba(0,0,0,0.2)'
          });
        });
        this.chartData = _.sortBy(this.chartData, function(series) {
          if (series.name === 'Average') {
            return 0;
          } else if (_this.individualResortMode && series.name === _this.firstSeasonName) {
            return 1;
          } else {
            return _this.averageBaseMap[series.name];
          }
        });
        return this.chartData = this.chartData.reverse();
      };

      ResortDataPane.prototype.compareResorts = function() {
        var _this = this;

        $('.resort-list-item-selected').removeClass('resort-list-item-selected');
        $('#compare-resorts-link').addClass('resort-list-item-selected');
        this.$('#resort-data').html(this.loadingMessageHTML);
        this.$('#resort-name').html('Comparative Base Depth');
        this.model = void 0;
        if (_.size(SnowDays._resortMap) === 0) {
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

      ResortDataPane.prototype.resortClickedHandler = function(model) {
        var _this = this;

        this.model = model;
        this.$('#resort-name').html(this.model.get('formatted_name') + ' Base Depth');
        this.$('#resort-data').html(this.loadingMessageHTML);
        if (!SnowDays._resortMap[this.model.get('name')]) {
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
    ResortSearchBox = (function(_super) {
      __extends(ResortSearchBox, _super);

      function ResortSearchBox() {
        _ref6 = ResortSearchBox.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      ResortSearchBox.prototype.el = $('#resort-list-search-box');

      ResortSearchBox.prototype.initialize = function() {
        return this.$el = $(this.el);
      };

      ResortSearchBox.prototype.events = {
        'keyup': 'filterResults'
      };

      ResortSearchBox.prototype.filterResults = function() {
        var filter;

        if (this.$el.val()) {
          filter = this.$el.val().trim().toUpperCase();
        }
        if (filter) {
          return _.each($('.resort-list-item'), function(resortItem) {
            if ($(resortItem).text().toUpperCase().indexOf(filter) > -1) {
              return $(resortItem).removeClass('slide-down');
            } else {
              return $(resortItem).addClass('slide-down');
            }
          });
        } else {
          return $('.resort-list-item').removeClass('slide-down');
        }
      };

      return ResortSearchBox;

    })(Backbone.View);
    AppView = (function(_super) {
      __extends(AppView, _super);

      function AppView() {
        _ref7 = AppView.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      AppView.prototype.el = $('#app');

      AppView.prototype.events = {
        'click #compare-resorts-link': 'compareResortsClickHandler'
      };

      AppView.prototype.initialize = function() {
        Resorts.bind('sync', this.render, this);
        Resorts.fetch();
        return setTimeout((function() {
          return SnowDays.fetch();
        }), 3000);
      };

      AppView.prototype.compareResortsClickHandler = function() {
        return Backbone.Events.trigger('compareResortsClicked');
      };

      AppView.prototype.appendResort = function(resort) {
        var resortView;

        resortView = new ResortView({
          model: resort
        });
        return this.$('#resort-list').append(resortView.render().el);
      };

      AppView.prototype.appendAllResorts = function() {
        var sortedResortList,
          _this = this;

        sortedResortList = _.sortBy(Resorts.models, function(resort) {
          return resort.get('formatted_name');
        });
        return _.each(sortedResortList, function(resort) {
          return _this.appendResort(resort);
        });
      };

      AppView.prototype.renderResortDataPane = function() {
        return this.resortDataPane = new ResortDataPane();
      };

      AppView.prototype.initResortSearchBox = function() {
        return this.resortSearchBox = new ResortSearchBox();
      };

      AppView.prototype.render = function() {
        this.appendAllResorts();
        this.initResortSearchBox();
        return this.renderResortDataPane();
      };

      return AppView;

    })(Backbone.View);
    return new AppView();
  });

}).call(this);
