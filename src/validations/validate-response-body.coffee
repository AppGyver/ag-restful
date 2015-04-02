types = require 'ag-types'
{Failure} = types.data.Validation

validatorToResponseValidator = (validator) ->
  if typeof validator is 'function'
    types.OneOf [
      types.Property 'body', validator
      types.Property 'text', validator
    ]
  else
    types.OneOf (
      for responseCode, responseBodyValidator of validator
        # NOTE: This checks for the contents but not response code
        # TODO: Check for response status
        validatorToResponseValidator responseBodyValidator
    )

# Validator data | Map responseCode (Validator data) -> Validator response
module.exports = responseValidator = (responseDataValidator) ->
  do (validateResponse = validatorToResponseValidator responseDataValidator) ->
    (response) ->
      if response.error
        Failure [response.error]
      else
        validateResponse response
