Promise = require 'bluebird'
express = require "express"

PORT = process.env.PORT || 9001

module.exports = withServer = (f) ->
  app = express()
  (new Promise (resolve) ->
    server = app.listen PORT, ->
      resolve server
  ).then (server) ->
    (new Promise (resolve, reject) ->
      Promise.resolve(f(app)).then(resolve, reject)
    ).finally ->
      new Promise (resolve) ->
        server.close resolve
