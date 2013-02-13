_s = require 'underscore.string'


exports.baseUrl = 'http://' + process.env.HOST

exports.trim = (string, characters) ->
	if (string is null) or (string is undefined)
		return string
	_s.trim string, characters
