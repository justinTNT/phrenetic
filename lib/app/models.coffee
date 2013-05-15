module.exports = (DS, App, schemas) ->
	_ = require 'underscore'
	Types = require('../schemas').Types


	BaseModel = DS.Model.extend
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
		validateRecord: (cb) ->
			async = require 'async'
			# TODO does 'attributes' include belongsTo and hasMany relationships?
			fields = @get('constructor.attributes.keys').toArray()
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

	for schemaName, definition of schemas
		properties = {}
		for pathName, path of definition
			if _.isFunction path
				# Shorthand schema path definition, just 'String', 'Date', etc.
				schemas[schemaName][pathName] = path = type: path
			# TODO probably need some followup for this choice, which is probably too inclusive, at least putting something sensible in the
			# schema for it (instead of whatever nested junk is already there).
			if not path.type
				if _.isObject(path)
					properties[pathName] = DS.attr 'object'
				if _.isArray(path)
					properties[pathName] = DS.attr 'array'
			else
				properties[pathName] =
					switch path.type
						# TODO check if path is an array or literal/Types.Mixed. An array of ObjectId's is a hasMany.
						when String then DS.attr 'string'
						when Date then DS.attr 'date'
						when Boolean then DS.attr 'boolean'
						when Number then DS.attr 'number'
						when Types.ObjectId then DS.belongsTo 'App.' + path.ref
						# TODO other types, and being back throw new error
						# else
						# 	throw new Error
			# TODO Make a generic 'verifyUniqueness'-type route for the 'unique' validator.
		model = App[schemaName] = BaseModel.extend properties
		model.reopen schema: definition
