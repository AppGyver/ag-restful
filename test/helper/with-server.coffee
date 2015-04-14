Promise = require 'bluebird'
express = require "express"

PORT = require '../http/port'

module.exports = withServer = (f) ->
  app = express()

  # Match server endpoint constructor signatures with http request constructor signature
  app.del = app.delete

  (new Promise (resolve) ->
    server = app.listen PORT, ->
      resolve server
  ).then (server) ->
    (new Promise (resolve, reject) ->
      Promise.resolve(f(app)).then(resolve, reject)
    ).finally ->
      new Promise (resolve) ->
        server.close resolve
