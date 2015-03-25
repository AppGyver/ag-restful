module.exports = (Promise) ->
  # Validation a -> Promise a
  return validationToPromise = (validation) ->
    validation.fold(
      (errors) -> Promise.reject new Error JSON.stringify(errors)
      (value) -> Promise.resolve value
    )
