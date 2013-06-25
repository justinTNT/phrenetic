module.exports = (preHook, postHook) ->

	require '../vendor'

	CONFIG_VARIABLES

	# TraceKit.report.subscribe (stacktrace) ->
	# 	# TODO log the stacktrace, logged in user, and router path
	# 	console.log stacktrace

	# Ember.onerror = (err) ->
	# 	alert 'asdf'
	# 	console.log err

	window.App = Ember.Application.create
		LOG_TRANSITIONS: process.env.NODE_ENV is 'development'
	App.deferReadiness()
	App.ready = ->
		$('#initializing').remove()

	io = require 'express.io/node_modules/socket.io/node_modules/socket.io-client'
	socket = io.connect require('./util').baseUrl
	socket.on 'error', ->
		# TODO remove once I'm convinced this never happens
		alert 'Unable to establish connection, please refresh.'
		# window.location.reload()
	socket.on 'reloadApp', ->
		window.location.reload()
	socket.on 'reloadStyles', ->
		App.styles.set 'timestamp', Date.now()


	preHook? Ember, DS, App, socket

	App.addObserver 'title', ->
		title = App.get 'title'
		document.title = title
		# $('meta[property="og:title"]').attr 'content', title
	App.styles = do ->
		Styles = Ember.Object.extend
			updateSheet: (->
					href = '/' + @get('name') + '.css'
					if timestamp = @get('timestamp')
						href += '?timestamp=' + timestamp
					$('#styles').attr 'href', href
				).observes 'name', 'timestamp'
		Styles.create()

	require('./store') Ember, DS, App, socket
	require('./ember') Ember, App

	require('./handlebars') Ember, Handlebars

	postHook? Ember, DS, App, socket
