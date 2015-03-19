validationToPromise = require './validation-to-promise'

# (a -> Validation b) -> (a -> Promise b)
module.exports = validatorToPromised = (validator) ->
  (args...) ->
    validationToPromise validator(args...)
