http = require './http'
restful = require('./build-restful-object')(http)
restful.ajax = http

module.exports = restful
