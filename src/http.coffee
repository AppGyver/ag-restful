
Promise = require 'bluebird'
_ = {
  merge: require 'lodash-node/modern/objects/merge'
}
buildRequest = require './http/build-request'

# requestBuilder -> Promise res
requestBuilderToResponsePromise = (requestBuilder) ->
  new Promise (resolve, reject) ->
    requestBuilder.end (err, res) ->
      if err
        reject err
      else
        resolve res

responsetoResponseBody = (response) ->
  if response.error
    throw new Error response.status
  else if response.body
    response.body
  else if response.text
    response.text
  else
    throw new Error "Empty response"

request = (method, path, options = {}) ->
  requestBuilderToResponsePromise buildRequest(method, path, options)

requestDataByMethod = (method) -> (path, options = {}) ->
  request(method, path, options)
    .then(responsetoResponseBody)

module.exports = http =
  # Returns the raw HTTP request
  request: request

  # These will always return the request data
  get: requestDataByMethod 'get'
  post: requestDataByMethod 'post'
  del: requestDataByMethod 'del'
  put: requestDataByMethod 'put'
