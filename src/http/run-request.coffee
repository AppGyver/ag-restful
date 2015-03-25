Promise = require 'bluebird'

###
requestBuilderToResponse: (requestBuilder: superagent) -> Promise response
###
module.exports = requestBuilderToResponse = (requestBuilder) ->
  new Promise (resolve, reject) ->
    requestBuilder.end (err, res) ->
      if err
        reject err
      else
        resolve res
