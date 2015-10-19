module.exports = (Promise, Bacon) ->
  http = require('./http')(Promise, Bacon)
  validations = require('./validations')(Promise)
  buildRestful = require('./build-restful-method')(http, validations)
  restful = require('./build-restful-object')(buildRestful, validations.validateResponseBody)

  restful.http = http

  restful
