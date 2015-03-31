debug = require('debug')('ag-restful:http')

module.exports = (Promise) ->
  ###
  requestBuilderToResponse: (requestBuilder: superagent) -> Promise response
  ###
  return requestBuilderToResponse = (requestBuilder) ->
    new Promise (resolve, reject) ->
      debug "Firing HTTP request", requestBuilder
      requestBuilder.end (err, res) ->
        if err
          debug "HTTP request error", err
          reject err
        else
          debug "HTTP request completed", res
          resolve res
