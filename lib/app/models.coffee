module.exports = (DS, App, schemas) ->
	_ = require 'underscore'
	Types = require('../schemas').Types


	baseModelProperties =
		typeName: (->
				util = require './util'
				util.typeName this
			).property()
	BaseModel = DS.Model.extend App.Validatable, baseModelProperties
	BaseModel.reopenClass baseModelProperties


	for schema in schemas.all()
		properties = {}
		for pathName, path of schema.definition
			if _.isFunction path
				# Shorthand schema path definition, just 'String', 'Date', etc.
				schemas[schema.name].definition[pathName] = path = type: path
			# TODO probably need some followup for this choice, which is probably too inclusive, at least putting something sensible in the
			# schema for it (instead of whatever nested junk is already there).
			if not path.type
				# Nested schema or array. Either way remove the path definition.
				schemas[schema.name].definition[pathName] = {}
				if _.isObject(path)
					properties[pathName] = DS.attr 'object'
				if _.isArray(path)
					properties[pathName] = DS.attr 'array', defaultValue: []
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
		baseClass = BaseModel
		if schema.base
			baseClass = App[schema.base]
			_s = require 'underscore.string'
			DS.Adapter.configure 'App.' + schema.name, alias: _s.underscored(schema.name)
			_.extend schema.definition, schemas[schema.base].definition
		model = App[schema.name] = baseClass.extend properties
		model.reopen schema: schema.definition
		model.reopenClass schema: schema.definition
