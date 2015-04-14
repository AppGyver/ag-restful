extractResponseBody = require './http/extract-response-body'

module.exports = (Promise) ->
  asyncJobRequestRunner = require('./http/async-job-request-runner')(Promise)

  runRequest = (args...) ->
    asyncJobRequestRunner(args...).run (t) ->
      t.done

  requestDataByMethod = (method) -> (path, options = {}) ->
    runRequest(method, path, options)
      .then(extractResponseBody)

  return http =
    transactional:
      request: asyncJobRequestRunner

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
