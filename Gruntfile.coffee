module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    uglify: 
      options: 
        banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
      build:
      	files:
      		'public/js/app-min.js': 'public/js/app.js'
        # src: 'public/js/<%= pkg.name %>.js'
        # dest: 'public/js/<%= pkg.name %>.min.js'
    coffee:
      compile:
        files:
          'public/js/app.js': 'public/js/app.coffee'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.registerTask 'default', ['coffee', 'uglify']