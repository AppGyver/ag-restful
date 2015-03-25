module.exports = (Promise) ->
  validationToPromise = require('./validation-to-promise')(Promise)
  validatorToPromised = require('./validator-to-promised')(validationToPromise)
  validateResponseBody = require './validate-response-body'
  return {
    validateResponseBody
    validationToPromise
    validatorToPromised
  }
