module.exports = (validationToPromise) ->
  # (a -> Validation b) -> (a -> Promise b)
  return validatorToPromised = (validator) ->
    (args...) ->
      validationToPromise validator(args...)
