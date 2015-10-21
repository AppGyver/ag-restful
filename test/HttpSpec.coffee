Promise = require 'bluebird'
Bacon = require 'baconjs'

{ http } = require('../src')(Promise, Bacon)

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

deepEqual = require 'deep-equal'
deepClone = require 'lodash-node/modern/lang/cloneDeep'

jsc = require 'jsverify'
arbitrary = require './data/arbitrary'

withServer = require './helper/with-server'
localhost = require './http/localhost'
asyncJob = require './http/async-job'

describe "ag-restful.http", ->
  describe "requests", ->
    it 'is a stream', ->
      http.should.have.property('requests').have.property('onValue').be.a 'function'

    jsc.property "contains an entry for each request started", arbitrary.httpMethod, arbitrary.requestOptions, (method, options) ->
      options = deepClone options
      withServer (app) ->
        foundRequestEvent = new Promise (resolve) ->
          originalOptions = deepClone options
          http
            .requests
            .filter((details) ->
              # Note: headers will not match because they're modified while
              # sending; only check query.
              (details.method is method) && \
                ((details.url || '').indexOf('/path') isnt -1) && \
                (deepEqual originalOptions.query, details.options.query)
            )
            .take(1)
            .onEnd resolve

        app[method] '/path', (req, res) ->
          foundRequestEvent.then ->
            res.status(200).end()

        http.request(method, "#{localhost}/path", options).then (response) ->
          response.status is 200

  describe "request()", ->
    jsc.property "performs http request to endpoint", arbitrary.httpMethod, (method) ->
      withServer (app) ->
        app[method] '/path', (req, res) ->
          res.status(200).end()

        http.request(method, "#{localhost}/path").then (response) ->
          response.status is 200

    describe "regressions", ->
      jsc.property "does not modify option arguments", arbitrary.httpMethod, arbitrary.requestOptions, (method, options) ->
        options = deepClone options
        withServer (app) ->
          app[method] '/path', (req, res) ->
            res.status(200).end()

          originalOptions = deepClone options
          http.request(method, "#{localhost}/path", options).then ->
            deepEqual(originalOptions, options)

  describe "transactional", ->
    describe "request()", ->
      jsc.property "yields a runnable", arbitrary.httpMethod, (method) ->
        'function' is typeof http.transactional.request(method, "/path").run

      jsc.property "transparently supports async job protocol", arbitrary.httpMethod, (method) ->
        withServer (app) ->
          app[method] '/path', asyncJob (req, res) ->
            res.status(200).end()

          http.transactional.request(method, "#{localhost}/path").run((t) ->
            t.done
          ).then (response) ->
            response.status is 200

      jsc.property "allows aborting the request", arbitrary.httpMethod, (method) ->
        withServer (app) ->
          ###
          KLUDGE: The current transaction doesn't handle immediate abortions.
          Also, we want to verify whether we can actually abort the ongoing
          HTTP request. To do this, we add a delay to the abort sufficiently
          long so that we have time to reach the HTTP request part.
          ###
          app[method] '/path', asyncJob (req, res) ->
            Promise.delay(100).then ->
              res.status(200).end()

          http.transactional.request(method, "#{localhost}/path").run (t) ->
            t.done.should.be.rejected
            Promise.delay(10).then ->
              t.abort().then ->
                true
