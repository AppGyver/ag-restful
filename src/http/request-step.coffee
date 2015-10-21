debug = require('debug')('ag-restful:http')

buildRequest = require './build-request'

module.exports = (Promise, Step, requestStarted) ->
  ###
  requestStep: (method, url, options) -> TransactionRunner superagent.Response
  ###
  requestStep = (method, url, options) ->
    request = buildRequest method, url, options

    Step ({ abort }) ->
      abort ->
        new Promise (resolve) ->
          request.once('abort', resolve)
          request.abort()

      done = new Promise (resolve, reject) ->
        debug "Firing HTTP request", request
        request.end (err, res) ->
          if err
            debug "HTTP request error", err
            reject err
          else
            debug "HTTP request completed", res
            resolve res

      requestStarted(
        method
        url
        options || {}
        done
      )

      done
