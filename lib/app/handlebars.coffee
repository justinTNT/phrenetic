module.exports = (Ember, Handlebars) ->
	_s = require 'underscore.string'


	Ember.Handlebars.registerHelper 'is', (path, options) ->
		view = Ember.View.create isVisible: false
		view.registerObserver this, path, ->
			value = @get path
			visible = false
			if (values = options.hash.values?.split(', ')) and (value in values)
				visible = true
			if value is options.hash.value
				visible = true
			view.set 'isVisible', visible
		Ember.Handlebars.ViewHelper.helper this, view, options

		# This is the way I'd like to do it but it doesn't work
		# if values = options.hash.values?.split(', ')
		# 	if value in values
		# 		return options.fn this
		# 	else
		# 		return options.inverse this
		# if value is options.hash.value
		# 	return options.fn this
		# options.inverse this
