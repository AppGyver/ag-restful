debug = require('debug')('ag-restful:http')

module.exports = (Promise, Transaction) ->
  ###
  requestRunner: (request: superagent.Request) -> TransactionRunner superagent.Response
  ###
  return requestRunner = (request) ->
    Transaction.step ({ abort }) ->
      abort ->
        new Promise (resolve) ->
          request.once('abort', resolve)
          request.abort()

      new Promise (resolve, reject) ->
        debug "Firing HTTP request", request
        request.end (err, res) ->
          if err
            debug "HTTP request error", err
            reject err
          else
            debug "HTTP request completed", res
            resolve res
