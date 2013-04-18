module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    requirejs: 
      compile:
        options:
          name: 'app'
          exclude: ['jquery', 'jqueryui']
          baseUrl: "public/js"
          mainConfigFile: "config.js"
          out: "public/dist/main-built.js"
    coffee:
      compile:
        files:
          'public/js/app.js': 'public/coffee/app.coffee'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-requirejs'

  grunt.registerTask 'default', ['coffee', 'requirejs']