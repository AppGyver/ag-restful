buildRequest = require './http/build-request'
extractResponseBody = require './http/extract-response-body'
jobs = require './http/jobs'

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

module.exports = (Promise) ->
  Transaction = require('ag-transaction')(Promise)
  requestRunner = require('./http/request-runner')(Promise, Transaction)

  retryingRequestRunner = do ->
    (method, path, options = {}) ->
      allowAsyncJobResponse options
      ###
      (f: () ->
        TransactionRunner ((superagent.Response & asyncJob) | superagent.Response)
      ) -> TransactionRunner superagent.Response
      ###
      retryUntilComplete = (f) ->
        f().flatMapDone (response) ->
          if !isAsyncJobResponse response
            Transaction.unit response
          else
            markAsAsyncJobMonitorRequest response, options
            retryUntilComplete f

      # NOTE: Node will emit faux 'socket hang up' errors if request is built
      # but never ran. Avoid this by starting from an empty transaction and
      # creating the request only when we're actually going to run.
      Transaction.empty.flatMapDone ->
        retryUntilComplete ->
          requestRunner buildRequest(method, path, options)

  runRequest = (args...) ->
    retryingRequestRunner(args...).run (t) ->
      t.done

  requestDataByMethod = (method) -> (path, options = {}) ->
    runRequest(method, path, options)
      .then(extractResponseBody)

  return http =
    transactional:
      request: retryingRequestRunner

    ###
    Runs a request and returns the raw superagent response object

    (method, url, options?) -> Promise Response
    ###
    request: runRequest

    ###
    Convenience functions that run a request and return its body as JSON

    (url, data?) -> Promise Object
    ###
    get: requestDataByMethod 'get'
    post: requestDataByMethod 'post'
    del: requestDataByMethod 'del'
    put: requestDataByMethod 'put'
