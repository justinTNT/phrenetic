module.exports = (root, projectRoot, app, variables) ->
	path = require 'path'


	bundle = require('browserify')
		exports: 'process'
		watch: process.env.NODE_ENV is 'development'
		# debug: true
	bundle.register 'post', (body) ->
		if process.env.NODE_ENV isnt 'production' then return body		# maybe should test for NODE_ENV is 'development'
		require('uglify-js').minify(body, fromString: true).code
	bundle.register '.jade', (body, filename) ->
		include = 'include ' + path.relative(path.dirname(filename), path.join(root, 'views/handlebars')) + '\n'
		data = require('jade').compile(include + body, filename: filename)()
		data = data.replace /(action|bindAttr)="(.*?)"/g, (all, name, args) -> '{{' + name + ' ' + args.replace(/&quot;/g, '"') + '}}'
		data = data.replace(/(\r\n|\n|\r)/g, '').replace(/'/g, '&apos;')
		'module.exports = Ember.Handlebars.compile(\'' + data + '\');'
	bundle.register (body) ->
		_ = require 'underscore'
		config = _.reduce variables, (memo, variable) ->
			memo + 'process.env.' + variable + ' = \'' + process.env[variable] + '\';\n'
		, ''
		body.replace 'CONFIG_VARIABLES', config
	bundle.on 'syntaxError', (err) ->
		throw new Error err
	bundle.addEntry 'lib/app/index.coffee'

	app.get '/app.js', do ->
		code = bundle.bundle()
		bundle.on 'bundle', ->
			code = bundle.bundle()
		(req, res) ->
			res.header 'Content-Type', 'application/javascript'
			res.send code

	pipeline = require('convoy') do ->
		createConfig = (name) ->
			main: projectRoot + '/styles/' + name
			packager: require 'convoy-stylus'
			postprocessors: [ (asset, context, done) ->
				basePath = projectRoot + '/styles/' + name + 'Base.less'
				context.watchPath basePath
				fs = require 'fs'
				fs.readFile basePath, 'utf8', (err, body) ->
					return done err if err
					less = require 'less'
					options =
						filename: basePath
						paths: [path.dirname(basePath)]
					new less.Parser(options).parse body, (err, tree) ->
						return done err if err
						asset.body = tree.toCSS() + '\n' + asset.body
						done()
			]
			minify: process.env.NODE_ENV is 'production'
			autocache: process.env.NODE_ENV is 'development'

		watch: process.env.NODE_ENV is 'development'
		'site.css': createConfig('site')
		'admin.css': createConfig('admin')
			


	bundle: bundle
	pipeline: pipeline
