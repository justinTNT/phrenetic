module.exports = (setup) ->

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
		$('#styles').attr 'href', '/app.css?timestamp=' + Date.now()

	require('./store') Ember, DS, App, socket
	require('./ember') Ember, App

	setup? Ember, DS, App, socket
