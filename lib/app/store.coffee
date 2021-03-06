module.exports = (Ember, DS, App, socket) ->
	_ = require 'underscore'
	util = require './util'


	# Override this private helper to ensure that ember-data doesn't try to automatically pair up any inverses.
	DS._inverseRelationshipFor = ->

	adapter = DS.Adapter.create do ->
		find: (store, type, id) ->
			socket.emit 'db', op: 'find', type: util.typeName(type), id: id, (json) =>
				Ember.run this, ->
					@didFindRecord store, type, json, id
		findMany: (store, type, ids, owner) ->
			socket.emit 'db', op: 'find', type: util.typeName(type), ids: ids, (json) =>
				Ember.run this, ->
					@didFindMany store, type, json
		findQuery: (store, type, query, recordArray) ->
			socket.emit 'db', op: 'find', type: util.typeName(type), query: util.normalizeQuery(query), (json) =>
				Ember.run this, ->
					@didFindQuery store, type, json, recordArray
		findAll: (store, type, since) ->
			socket.emit 'db', op: 'find', type: util.typeName(type), (json) =>
				Ember.run this, ->
					@didFindAll store, type, json

		createRecord: (store, type, record) ->
			socket.emit 'db', op: 'create', type: util.typeName(type), record: record.serialize(), (json) =>
				Ember.run this, ->
					@didCreateRecord store, type, record, json
		updateRecord: (store, type, record) ->
			rec = record.serialize(includeId:false)
			rec.id = String(record.get 'id')
			socket.emit 'db', op: 'save', type: util.typeName(type), record: rec, (json) =>
				Ember.run this, ->
					@didSaveRecord store, type, record, json
		deleteRecord: (store, type, record) ->
			socket.emit 'db', op: 'remove', type: util.typeName(type), id: record.get('id'), =>
				Ember.run this, ->
					@didSaveRecord store, type, record

		serializer: DS.JSONSerializer.extend
			addHasMany: (hash, record, key, relationship) ->
				@_super hash, record, key, relationship
				type = record.constructor
				name = relationship.key
				if not @embeddedType type, name
					ids = record.get(name).getEach('id')
					hash[key] = ids


	# Technically these probably shouldn't be on the adapter.
	adapter.registerTransform 'array',
		serialize: (deserialized) ->
			deserialized
		deserialize: (serialized) ->
			serialized
	adapter.registerTransform 'object',
		serialize: (deserialized) ->
			deserialized
		deserialize: (serialized) ->
			serialized
	# TO-DO Workarounds for JSONSerializer turning undefined into null, remove when ember-data stops doing this.
	adapter.registerTransform 'date',
		serialize: (deserialized) ->
			deserialized
		deserialize: (serialized) ->
			validators = require('validator').validators
			if serialized
				throw new Error 'Invalid date.' if not validators.isDate serialized
				return new Date serialized
	adapter.registerTransform 'string',
		serialize: (value) -> value
		deserialize: (value) -> value
	adapter.registerTransform 'number',
		serialize: (value) -> value
		deserialize: (value) -> value
	adapter.registerTransform 'boolean',
		serialize: (value) -> value
		deserialize: (value) -> value


	App.store = DS.Store.create
		adapter: adapter
