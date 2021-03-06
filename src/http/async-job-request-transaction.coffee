defaults = require 'lodash-node/modern/object/defaults'
deepClone = require 'lodash-node/modern/lang/cloneDeep'

jobs = require './jobs'

###
We want to be able to modify headers on the options object. However, there's
data that is potentially uncloneable. Let's do a partial clone.
###
partialCloneOptions = (requestOptions) ->
  defaults(
    # Start with specific cloned properties
    {
      headers: deepClone (requestOptions.headers ? {})
      query: deepClone (requestOptions.query ? {})
    },
    # Leave the rest up to the original object's values
    requestOptions
  )

###
Allow the server to respond with an async job by enabling the corresponding feature header
###
allowAsyncJobResponse = (requestOptions) ->
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
  requestOptions.headers[jobs.JOB_ID_HEADER] = asyncJobResponse.body[jobs.JOB_ROOT_KEY].id

module.exports = (Promise, requestStarted) ->
  Transaction = require('ag-transaction')(Promise)
  requestStep = require('./request-step')(Promise, Transaction.step, requestStarted)

  return asyncJobRequestTransaction = (method, url, options = {}) ->
    options = partialCloneOptions options
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
        requestStep method, url, options
