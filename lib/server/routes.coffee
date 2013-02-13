module.exports = (projectRoot, app) ->

	route = (name, cb) ->
		app.io.route name, (req) ->
			cb req.io.respond, req.data, req.io, req.session


	route 'session', (fn, data, io, session) ->
		fn session

	route 'logout', (fn, data, io, session) ->
		session.destroy()
		fn()


	require(projectRoot + '/lib/server/routes') app, route
