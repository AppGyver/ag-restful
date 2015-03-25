Promise = require 'bluebird'
http = require('../src/http')(Promise)

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

jsc = require 'jsverify'
generators = require './generators'

arbitraryHttpMethod = jsc.elements ['get', 'post', 'put', 'del']
withServer = require './with-server'
localhost = require './http/localhost'

# jsverify 0.6.0-alpha3 has a bug where async properties aren't verified with jsc.property
# circumvent this by a custom combinator
property = (description, args...) ->
  it description, ->
    jsc.check(jsc.forall(args...)).then (holds) ->
      if holds is true
        true
      else
        # holds contains counterexample
        throw new Error "property does not hold, counterexample: #{holds.counterexamplestr}"

describe "ag-restful.http", ->
  describe "request()", ->
    property "performs http request to endpoint with any method", arbitraryHttpMethod, (method) ->
      withServer (app) ->
        app[method] '/path', (req, res) ->
          res.status(200).end()

        http.request(method, "#{localhost}/path").then (response) ->
          response.status is 200
