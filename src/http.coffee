_ = {
  merge: require 'lodash-node/modern/object/merge'
}
buildRequest = require './http/build-request'
extractResponseBody = require './http/extract-response-body'
jobs = require './http/jobs'

module.exports = (Promise) ->
  requestRunner = require('./http/request-runner')(Promise)
  runRequest = (requestBuilder) ->
    requestRunner(requestBuilder).run (t) ->
      t.done

  ###
  Allow the server to respond with an async job by enabling the corresponding feature header
  ###
  allowAsyncJobResponse = (requestOptions) ->
    requestOptions.headers ?= {}
    requestOptions.headers[jobs.ASYNC_JOB_FEATURE_HEADER] = true

  ###
  Check a response for the signature of an async job
  ###
  isAsyncJobResponse = (response) ->
    (response.status is jobs.JOB_HTTP_STATUS) and (response.body?[jobs.JOB_ROOT_KEY]?.id?)

  ###
  Given an async job response, mark a request as a monitor on the async job by setting a header
  ###
  markAsAsyncJobMonitorRequest = (asyncJobResponse, requestOptions) ->
    requestOptions.headers ?= {}
    requestOptions.headers[jobs.JOB_ID_HEADER] = asyncJobResponse.body[jobs.JOB_ROOT_KEY].id

  request = (method, path, options = {}) ->
    allowAsyncJobResponse options
    ###
    (f: () -> Promise (asyncJobResponse | response)) -> Promise response
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
    transactional:
      request: (args...) ->
        requestRunner buildRequest args...

    ###
    Runs a request and returns the raw superagent response object

    (method, url, options?) -> Promise Response
    ###
    request: request

    ###
    Convenience functions that run a request and return its body as JSON

    (url, data?) -> Promise Object
    ###
    get: requestDataByMethod 'get'
    post: requestDataByMethod 'post'
    del: requestDataByMethod 'del'
    put: requestDataByMethod 'put'
