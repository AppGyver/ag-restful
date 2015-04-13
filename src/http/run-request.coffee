debug = require('debug')('ag-restful:http')

module.exports = (Promise) ->
  requestRunner = require('./request-runner')(Promise)

  return requestBuilderToResponse = (requestBuilder) ->
    requestRunner(requestBuilder).run (t) ->
      t.done
