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
	
	App.ready = ->
		$('#initializing').remove()

	io = require 'socket.io-client'
	socket = io.connect require('./util').baseUrl
	socket.on 'error', ->
		# TODO remove once I'm convinced this never happens
		alert 'Unable to establish connection, please refresh.'
		# window.location.reload()
	socket.on 'reloadApp', ->
		window.location.reload()
	socket.on 'reloadStyles', ->
		$('#styles').attr 'href', '/app.css?timestamp=' + Date.now()

	require('./store') DS, App, socket
	require('./ember') Ember, App

	setup? Ember, DS, App, socket

	socket.emit 'session', (session) ->
		if id = session.user
			App.auth.login id
		else
			App.auth.logout()
		App.initialize()
