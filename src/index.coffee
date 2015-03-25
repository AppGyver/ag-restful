Promise = require 'bluebird'

http = require('./http')(Promise)
restful = require('./build-restful-object')(http)
restful.ajax = http

module.exports = restful
