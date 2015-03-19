Promise = require 'bluebird'

# Validation a -> Promise a
module.exports = validationToPromise = (validation) ->
  validation.fold(
    (errors) -> Promise.reject new Error JSON.stringify(errors)
    (value) -> Promise.resolve value
  )
