module.exports = (schemas) ->

	# Open a database connection.
	db = require('./services').getDb()
	
	common = (schema) ->
		schema.set 'toJSON', getters: true   # To make 'id' included in json serialization for the data API.






	Schema = db.Schema

	# Overwrite dummy types with mongoose types.
	Types = require('../schemas').Types
	for name of Types
		Types[name] = Schema.Types[name]

	models = {}
	for name, definition of schemas
		schema = new Schema definition
		schema.plugin common
		models[name] = db.model name, schema
	models
