debug = require('debug')('ag-restful:http')

module.exports = (Promise) ->
  Transaction = require('ag-transaction')(Promise)

  ###
  requestRunner: (request: superagent.Request) -> TransactionRunner superagent.Response
  ###
  return requestRunner = (request) ->
    Transaction.step ->
      new Promise (resolve, reject) ->
        debug "Firing HTTP request", request
        request.end (err, res) ->
          if err
            debug "HTTP request error", err
            reject err
          else
            debug "HTTP request completed", res
            resolve res
