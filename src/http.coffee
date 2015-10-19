extractResponseBody = require './http/extract-response-body'

module.exports = (Promise, Bacon) ->
  asyncJobRequestRunner = require('./http/async-job-request-runner')(Promise)

  requests = new Bacon.Bus
  requestStarted = (method, url, options, done) ->
    requests.push {
      method
      url
      options
      done
    }

  runRequest = (args...) ->
    asyncJobRequestRunner(args...).run (t) ->
      [ method, url, options ] = args

      requestStarted(
        method
        url
        options || {}
        t.done
      )

      t.done

  requestDataByMethod = (method) -> (url, options = {}) ->
    runRequest(method, url, options)
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

    ###
    Bacon.Bus {
      method: String
      path: String
      options: Object
      done: Promise superagent.Response
    }
    ###
    requests: requests
