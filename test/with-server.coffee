Promise = require 'bluebird'
express = require "express"

module.exports = withServerAt = (port, f) ->
  app = express()
  (new Promise (resolve) ->
    server = app.listen port, ->
      resolve server
  ).then (server) ->
    (new Promise (resolve, reject) ->
      Promise.resolve(f(app)).then(resolve, reject)
    ).finally ->
      new Promise (resolve) ->
        server.close resolve
