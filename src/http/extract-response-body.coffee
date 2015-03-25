###
extractResponseBody: (response: Object) -> Object | Error
###
module.exports = extractResponseBody = (response) ->
  if response.error
    throw new Error response.status
  else if response.body
    response.body
  else if response.text
    response.text
  else
    throw new Error "Empty response"
