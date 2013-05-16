# Note: "Frame" means mongoose schema. I just picked another term so I wouldn't get them confused with my schemas.

db = require('./services').getDb()


exports.frame = (schemas) ->
	Schema = db.Schema

	# Overwrite dummy types with mongoose types.
	Types = require('../schemas').Types
	for name of Types
		Types[name] = Schema.Types[name]

	frames = {}
	for name, schema of schemas
		frame = new Schema schema
		frame.set 'toJSON', getters: true   # To make 'id' included in json serialization for the data API.
		frames[name] = frame
	frames


exports.compile = (frames) ->
	models = {}
	for name, frame of frames
		models[name] = db.model name, frame
	models
