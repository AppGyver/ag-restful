Promise = require 'bluebird'
{ http } = require('../src')(Promise)

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

jsc = require 'jsverify'
generators = require './generators'

arbitraryHttpMethod = jsc.elements ['get', 'post', 'put', 'del']
withServer = require './with-server'
localhost = require './http/localhost'
asyncJob = require './http/async-job'

describe "ag-restful.http", ->
  describe "request()", ->
    jsc.property "performs http request to endpoint with any method", arbitraryHttpMethod, (method) ->
      withServer (app) ->
        app[method] '/path', (req, res) ->
          res.status(200).end()

        http.request(method, "#{localhost}/path").then (response) ->
          response.status is 200

    jsc.property "transparently supports async job protocol with any method", arbitraryHttpMethod, (method) ->
      withServer (app) ->
        app[method] '/path', asyncJob (req, res) ->
          res.status(200).end()

        http.request(method, "#{localhost}/path").then (response) ->
          response.status is 200
