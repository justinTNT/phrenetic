module.exports = (Ember, App) ->
	_ = require 'underscore'


	App.findOne = (type, query = {}) ->
		util = require './util'
		query = util.normalizeQuery query
		query.options.limit = 1

		# TO-DO remove this old implementation if I never figue out how it was supposed to work: http://progfu.com/post/40016169330/how-to-find-a-model-by-any-attribute-in-ember-js
		# records = type.find query
		# records.one 'didLoad', ->
		# 	records.resolve records.get('firstObject')
		# records
		single = Ember.ObjectProxy.create()
		records = type.find query
		records.one 'didLoad', ->
			single.set 'content', records.get('firstObject')
		single


	App.refresh = (record) ->
		App.store.findQuery record.constructor, record.get('id')


	App.Pagination = Ember.Mixin.create
		rangeStart: 0
		totalBinding: 'content.length'
		itemsPerPage: 10
		paginatedItems: (->
				@get('content').slice @get('rangeStart'), @get('rangeStop')
			).property 'content.@each', 'rangeStart', 'rangeStop'

		rangeStop: (->
				Math.min @get('rangeStart') + @get('itemsPerPage'), @get('total')
			).property 'total', 'rangeStart', 'itemsPerPage'
		hasPrevious: (->
				@get('rangeStart') > 0
			).property 'rangeStart'
		hasNext: (->
				@get('rangeStop') < @get('total')
			).property 'rangeStop', 'total'
		previousPage: ->
			@decrementProperty 'rangeStart', @get('itemsPerPage')
		nextPage: ->
			@incrementProperty 'rangeStart', @get('itemsPerPage')

		# Probably need this eventually.
		# page: function() {
		#   return (get(this, 'rangeStart') / get(this, 'rangeWindowSize')) + 1;
		# }.property('rangeStart', 'rangeWindowSize').cacheable(),
		# totalPages: function() {
		#   return Math.ceil(get(this, 'total') / get(this, 'rangeWindowSize'));
		# }.property('total', 'rangeWindowSize').cacheable(),


	App.Validatable = Ember.Mixin.create
		filter: (name) ->
			schema = @get 'schema.' + name
			value = @get name
			if not value
				return
			if schema.trim
				util = require './util'
				value = util.trim value
			if schema.lowercase
				value = value.toLowerCase()
			if schema.uppercase
				value = value.toUpperCase()
			if set = schema.set
				value = set value
			@set name, value
		validate: do ->
			validators = require('validator').validators
			messages =
				required: 'Dudebro, you have to enter something dude, bro.'
				format: (type) ->
					'Pretty sure that\'s not a ' + type + '.'
				enum: 'That\'s not an acceptable choice.'
				unique: (type) ->
					'That ' + type + ' is in use.'
				min: 'Too low.'
				max: 'Too high.'
			(name, cb) ->
				schema = @get 'schema.' + name
				value = @get name
				finish = (message) =>
					# Only the first error message is recorded.
					if not @get 'errors'
						@set 'errors', {}
					# I'd like to use recordWasInvalid here but it doesn't seem to work unless it's after a server response.
					# App.store.recordWasInvalid this, errors
					@set 'errors.' + name, message or null
					cb?()
				if not value and ((not schema.required) or (schema.default))
					# Stop validating if the field isn't set and it's not required / will be populated with a default value later.
					return finish()
				if schema.required and not value
					return finish messages.required
				switch schema.type
					when String
						if not _.isString value
							return finish messages.format 'string'
					when Date
						if not validators.isDate value
							return finish messages.format 'date'
					when Boolean
						if value not in [true, false, 'true', 'false']
							return finish messages.format 'boolean'
					when Number
						if isNaN new Number(value)
							return finish messages.format 'number'
					# TODO when Types.ObjectId, bring back throw new Error
					# else
					# 	throw new Error
				if (rule = schema.validate) and not rule(value)
					return finish messages.format name
				if (enumeration = schema.enum) and value not in enumeration
					return finish messages.enum
				if (match = schema.match) and not match.test value
					return finish messages.format name
				if (min = schema.min) and value < min
					return finish messages.min
				if (max = schema.max) and value > max
					return finish messages.max
				# TODO have a route for checking uniqueness, something like this:
				# socket.emit 'verifyUniqueness', field: 'email', value: email, (duplicate) ->
				# 	if duplicate
				# 		return finish messages.unique 'email'
				# 	finish()
				finish()
		validateAll: (cb) ->
			async = require 'async'
			fields = _.keys @get('schema')
			async.each fields, (field, cb) =>
				@filter field
				@validate field, cb
			, cb
		hasErrors: ->
			not _.chain(@get('errors'))
				.values()
				.compact()
				.isEmpty()
				.value()


	App.FormData = Ember.Object.extend App.Validatable
