module.exports = (Promise) ->
  ###
  requestBuilderToResponse: (requestBuilder: superagent) -> Promise response
  ###
  return requestBuilderToResponse = (requestBuilder) ->
    new Promise (resolve, reject) ->
      requestBuilder.end (err, res) ->
        if err
          reject err
        else
          resolve res
