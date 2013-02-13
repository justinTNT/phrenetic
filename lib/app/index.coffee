module.exports = (setup) ->
	
	require '../vendor'

	CONFIG_VARIABLES

	# TraceKit.report.subscribe (stacktrace) ->
	# 	# TODO log the stacktrace, logged in user, and router path
	# 	console.log stacktrace

	# Ember.onerror = (err) ->
	# 	alert 'asdf'
	# 	console.log err

	window.App = Ember.Application.create autoinit: false

	io = require 'socket.io-client'
	socket = io.connect require('./util').baseUrl
	socket.on 'error', ->
		# TODO remove once I'm convinced this never happens
		alert 'Unable to establish connection, please refresh.'
		# window.location.reload()

	require('./store') DS, App, socket
	require('./ember') Ember, App

	setup? Ember, DS, App, socket

	socket.on 'reloadApp', ->
		window.location.reload()
	socket.on 'reloadStyles', ->
		stylesheet = $('link[href="/app.css"]')
		stylesheet.attr 'href', 'app.css?timestamp=' + Date.now()
