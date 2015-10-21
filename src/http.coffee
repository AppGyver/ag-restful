extractResponseBody = require './http/extract-response-body'

module.exports = (Promise, Bacon) ->
  requests = new Bacon.Bus
  requestStarted = (method, url, options, done) ->
    requests.push {
      method
      url
      options
      done
    }

  asyncJobRequestTransaction = require('./http/async-job-request-transaction')(Promise, requestStarted)

  runRequest = (args...) ->
    asyncJobRequestTransaction(args...).run (t) ->
      t.done

  requestDataByMethod = (method) -> (url, options = {}) ->
    runRequest(method, url, options)
      .then(extractResponseBody)

  return http =
    transactional:
      request: asyncJobRequestTransaction

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

    ###
    Bacon.Bus {
      method: String
      path: String
      options: Object
      done: Promise superagent.Response
    }
    ###
    requests: requests
