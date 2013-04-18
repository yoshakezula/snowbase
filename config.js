var require = {
  paths: {
    jquery: "libs/jquery/jquery-1.9.1.min",
    jqueryui: "libs/jquery/jquery-ui.min",
    backbone: "libs/backbone-min",
    underscore: "libs/underscore-min",
    bootstrap: "libs/bootstrap",
    d3: "libs/d3.min",
    rickshaw: "libs/rickshaw",
    app: 'app',
    modernizr: 'libs/modernizr.custom.min'
  },

  //Fix for rickshaw, which uses $super
  uglify: {
    except: ['$super']
  },

  shim: {
    jqueryui: ['jquery'],
    backbone: {
      deps: ['underscore', 'jquery'],
      exports: 'Backbone'
    },
    bootstrap: ['jquery', 'jqueryui'],
    rickshaw: {
      deps: ['d3'],
      exports: 'Rickshaw'
    },
    modernizr: {
      exports: 'Modernizr'
    },
    app: ['backbone', 'rickshaw', 'bootstrap', 'modernizr']
  },

  preserveLicenseComments: false,
  waitSeconds: 15
}