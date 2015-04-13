Promise = require 'bluebird'
{ http } = require('../src')(Promise)

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

jsc = require 'jsverify'

arbitraryHttpMethod = jsc.elements ['get', 'post', 'put', 'del']
withServer = require './helper/with-server'
localhost = require './http/localhost'
asyncJob = require './http/async-job'

describe "ag-restful.http", ->
  describe "request()", ->
    jsc.property "performs http request to endpoint", arbitraryHttpMethod, (method) ->
      withServer (app) ->
        app[method] '/path', (req, res) ->
          res.status(200).end()

        http.request(method, "#{localhost}/path").then (response) ->
          response.status is 200

  describe "transactional", ->
    describe "request()", ->
      jsc.property "yields a runnable", arbitraryHttpMethod, (method) ->
        'function' is typeof http.transactional.request(method, "/path").run

      jsc.property "transparently supports async job protocol", arbitraryHttpMethod, (method) ->
        withServer (app) ->
          app[method] '/path', asyncJob (req, res) ->
            res.status(200).end()

          http.transactional.request(method, "#{localhost}/path").run((t) ->
            t.done
          ).then (response) ->
            response.status is 200
