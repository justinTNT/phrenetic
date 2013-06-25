# Note: "Frame" means mongoose schema. I just picked another term so I wouldn't get them confused with my schemas.

require 'mongoose-schema-extend'
db = require('./services').getDb()
_ = require('underscore')


exports.frame = (schemas) ->
	Schema = db.Schema

	# Overwrite dummy types with mongoose types.
	Types = require('../schemas').Types
	for name of Types
		Types[name] = Schema.Types[name]

	frames = {}
	for schema in schemas.all()
		create = (definition, options) ->
			new Schema definition, options
		options = {}
		if schema.base
			# create = frames[schema.base].extend
			options.collection = require('mongoose/lib/utils').toCollectionName schema.base
			_ = require 'underscore'
			_.extend schema.definition, schemas[schema.base].definition
		if schema.definition._type
			options.discriminatorKey = '_type'
		for key of schema.definition							# each attribute on the schema
			val = schema.definition[key]
			if _.isArray val then val = val[0]					# if its an array, look at contents
			if val.type and _.isEmpty(val.type) and val.ref		# if it matches the O'Id {} placeholder
				val.type = Schema.Types.ObjectId				# swap in the real thing
		frame = create schema.definition, options
		frame.set 'toJSON', getters: true   # To make 'id' included in json serialization for the data API.
		frames[schema.name] = frame
		if schema.base
			frame.pre 'save', (next) ->
				@_type = @constructor.modelName
				next()
	frames


exports.compile = (frames) ->
	models = {}
	for name, frame of frames
		models[name] = db.model name, frame
	models
