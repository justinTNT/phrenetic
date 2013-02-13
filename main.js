require('coffee-script');
require('longjohn');

var projectRoot = require('path').dirname(module.parent.filename);

require('./lib/server/config')(projectRoot);
var module = process.argv[2];
require(projectRoot + '/lib/' + module);
