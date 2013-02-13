exports.db = require('./services').getDb()

exports.common = (schema) ->
	schema.add
		date: type: Date, required: true, default: Date.now
	schema.set 'toJSON', getters: true   # To make 'id' included in json serialization for the API.
