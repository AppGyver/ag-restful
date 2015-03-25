_ = {
  merge: require 'lodash-node/modern/objects/merge'
}
buildRequest = require './http/build-request'
extractResponseBody = require './http/extract-response-body'

module.exports = (Promise) ->
  runRequest = require('./http/run-request')(Promise)

  request = (method, path, options = {}) ->
    runRequest buildRequest(method, path, options)

  requestDataByMethod = (method) -> (path, options = {}) ->
    request(method, path, options)
      .then(extractResponseBody)

  return http =
    # Returns the raw HTTP request
    request: request

    # These will always return the request data
    get: requestDataByMethod 'get'
    post: requestDataByMethod 'post'
    del: requestDataByMethod 'del'
    put: requestDataByMethod 'put'
