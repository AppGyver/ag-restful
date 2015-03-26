_ = {
  merge: require 'lodash-node/modern/objects/merge'
}
buildRequest = require './http/build-request'
extractResponseBody = require './http/extract-response-body'
jobs = require './http/jobs'

module.exports = (Promise) ->
  runRequest = require('./http/run-request')(Promise)

  ###
  Check a response for the signature of an async job
  ###
  isAsyncJobResponse = (response) ->
    (response.status is jobs.JOB_HTTP_STATUS) and (response.header[jobs.JOB_ID_HEADER]?)

  ###
  Given an async job response, mark a request as a monitor on the async job by setting a header
  ###
  markAsAsyncJobMonitorRequest = (asyncJobResponse, requestOptions) ->
    requestOptions.headers ?= {}
    requestOptions.headers[jobs.JOB_ID_HEADER] = asyncJobResponse.header[jobs.JOB_ID_HEADER]

  request = (method, path, options = {}) ->
    ###
    (f: () -> (asyncJobResponse | response)) -> response
    ###
    retryUntilComplete = (f) ->
      f().then (response) ->
        if !isAsyncJobResponse response
          response
        else
          markAsAsyncJobMonitorRequest response, options
          retryUntilComplete f

    retryUntilComplete ->
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
