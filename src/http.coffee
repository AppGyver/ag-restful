_ = {
  merge: require 'lodash-node/modern/objects/merge'
}
buildRequest = require './http/build-request'
runRequest = require './http/run-request'
extractResponseBody = require './http/extract-response-body'

request = (method, path, options = {}) ->
  runRequest buildRequest(method, path, options)

requestDataByMethod = (method) -> (path, options = {}) ->
  request(method, path, options)
    .then(extractResponseBody)

module.exports = http =
  # Returns the raw HTTP request
  request: request

  # These will always return the request data
  get: requestDataByMethod 'get'
  post: requestDataByMethod 'post'
  del: requestDataByMethod 'del'
  put: requestDataByMethod 'put'
