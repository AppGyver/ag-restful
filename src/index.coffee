module.exports = (Promise) ->
  http = require('./http')(Promise)
  validations = require('./validations')(Promise)
  buildRestful = require('./build-restful-method')(http, validations)
  restful = require('./build-restful-object')(buildRestful, validations.validateResponseBody)
  restful.ajax = http

  restful
