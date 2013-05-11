module.exports = (Ember, App) ->

	App.findOne = (type, query) ->
		if not query.conditions
			query =
				conditions: query
				options: {}
		query.options.limit = 1
		records = type.find query
		records.one 'didLoad', ->
			records.resolve records.get('firstObject')
		records

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
