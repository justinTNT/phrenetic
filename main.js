require('coffee-script');
require('longjohn');

var projectRoot = require('path').dirname(module.parent.filename);

require('./lib/server/config')(projectRoot);

var module = process.argv[2];
if (module == 'server')
	require('./lib/server')(projectRoot);
try {
	require(projectRoot + '/lib/' + module);
} catch (err) {
	if (err.code != 'MODULE_NOT_FOUND')
		throw err;
	require('./lib/' + module);
}
