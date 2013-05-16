Types = {}
for type in ['ObjectId', 'Mixed']
	Types[type] = {}   # Create a different dummy object for each type.
exports.Types = Types

exports.addTimestamp = (schemas) ->
	_ = require 'underscore'
	for name, schema of schemas
		_.extend schema,
			date: type: Date, required: true, default: Date.now
