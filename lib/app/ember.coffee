module.exports = (Ember, App) ->

	App.findOne = (type, query = {}) ->
		util = require './util'
		query = util.normalizeQuery query
		query.options.limit = 1

		# TO-DO remove this old implementation if I never figue out how it was supposed to work: http://progfu.com/post/40016169330/how-to-find-a-model-by-any-attribute-in-ember-js
		# records = type.find query
		# records.one 'didLoad', ->
		# 	records.resolve records.get('firstObject')
		# records
		single = Ember.ObjectProxy.create()
		records = type.find query
		records.one 'didLoad', ->
			single.set 'content', records.get('firstObject')
		single


	App.refresh = (record) ->
		App.store.findQuery record.constructor, record.get('id')


	App.Pagination = Ember.Mixin.create
		rangeStart: 0
		totalBinding: 'content.length'
		itemsPerPage: 10
		paginatedItems: (->
				@get('content').slice @get('rangeStart'), @get('rangeStop')
			).property 'content.@each', 'rangeStart', 'rangeStop'

		rangeStop: (->
				Math.min @get('rangeStart') + @get('itemsPerPage'), @get('total')
			).property 'total', 'rangeStart', 'itemsPerPage'
		hasPrevious: (->
				@get('rangeStart') > 0
			).property 'rangeStart'
		hasNext: (->
				@get('rangeStop') < @get('total')
			).property 'rangeStop', 'total'
		previousPage: ->
			@decrementProperty 'rangeStart', @get('itemsPerPage')
		nextPage: ->
			@incrementProperty 'rangeStart', @get('itemsPerPage')

		# Probably need this eventually.
		# page: function() {
		#   return (get(this, 'rangeStart') / get(this, 'rangeWindowSize')) + 1;
		# }.property('rangeStart', 'rangeWindowSize').cacheable(),
		# totalPages: function() {
		#   return Math.ceil(get(this, 'total') / get(this, 'rangeWindowSize'));
		# }.property('total', 'rangeWindowSize').cacheable(),
