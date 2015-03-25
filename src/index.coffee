http = require './ag/http'
restful = require('./ag/build-restful-object')(http)
restful.ajax = http

module.exports = restful
