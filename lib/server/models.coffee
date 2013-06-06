# Note: "Frame" means mongoose schema. I just picked another term so I wouldn't get them confused with my schemas.

require 'mongoose-schema-extend'
db = require('./services').getDb()


exports.frame = (schemas) ->
	Schema = db.Schema

	# Overwrite dummy types with mongoose types.
	Types = require('../schemas').Types
	for name of Types
		Types[name] = Schema.Types[name]

	frames = {}
	for schema in schemas
		create = (definition, options) ->
			new Schema definition, options
		options = {}
		if schema.base
			# create = frames[schema.base].extend
			options.collection = require('mongoose/lib/utils').toCollectionName schema.base
			_ = require 'underscore'
			baseSchema = _.find schemas, (candidate) ->
				candidate.name is schema.base
			_.extend schema.definition, baseSchema.definition
		if schema.definition._type
			options.discriminatorKey = '_type'
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
