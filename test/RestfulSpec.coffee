Promise = require 'bluebird'
fs = require 'fs'
bodyparser = require "body-parser"
formidable = require 'formidable'

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

types = require 'ag-types'
restful = require '../src/ag/restful'

withServerAt = require './with-server'

describe "ag-restful", ->
  it "is a function", ->
    restful.should.be.a 'function'

  it "accepts options and a function and returns an object", ->
    restful({}, -> {}).should.be.an 'object'

  port = 9876
  app = null
  server = null

  withJsonServer = (f) ->
    withServerAt port, (app) ->
      app.use bodyparser.json()
      f app

  localRestful = (f) ->
    restful {
      baseUrl: "http://localhost:#{port}"
    }, f

  describe "restful()", ->

    it "has getOptions()", ->
      restful({}, -> {}).should.have.property('getOptions').be.a 'function'

    it "has setOptions()", ->
      restful({}, -> {}).should.have.property('setOptions').be.a 'function'

    describe "getOptions()", ->
      it "should have default headers if provided", ->
        Resource = restful { headers: foo: 'bar' }, -> {}
        Resource.getOptions().should.have.property('headers').deep.equal {
          foo: 'bar'
        }

      it "should allow overriding headers with setOptions", ->
        Resource = restful { headers: foo: 'bar' }, -> {}
        Resource.setOptions headers: foo: 'not bar'
        Resource.getOptions().should.have.property('headers').deep.equal {
          foo: 'not bar'
        }

      it "should deep merge defaults with setOptions", ->
        Resource = restful { headers: foo: 'bar' }, -> {}
        Resource.setOptions headers: qux: 'baz'
        Resource.getOptions().should.have.property('headers').deep.equal {
          foo: 'bar'
          qux: 'baz'
        }

      it "should revert back to defaults after clearing anything set with setOptions", ->
        Resource = restful { headers: foo: 'bar' }, -> {}
        Resource.setOptions headers: {
          foo: 'not bar'
          qux: 'baz'
        }
        Resource.setOptions {}
        Resource.getOptions().should.have.property('headers').deep.equal {
          foo: 'bar'
        }

    describe "API descriptor", ->
      it "determines a group of methods on the output object", ->
        restful({}, -> {
          foo: ->
          bar: ->
        }).should.include.keys ['foo', 'bar']

      it "receives a restful API builder", ->
        restful {}, (api) ->
          api.should.be.an 'object'

      describe "API builder", ->
        it "supports get, post, delete, put, request and response", ->
          restful {}, (api) ->
            api.should.include.keys ['get', 'post', 'delete', 'put', 'request', 'response']

        describe "get", ->
          it "creates a getter method", ->
            r = localRestful (api) ->
              foo: api.get
                receive: api.response types.Any
                path: -> '/foo'

            r.foo.should.be.a 'function'

            withJsonServer (app) ->
              app.get '/foo', (req, res) ->
                res.json {
                  bar: 'qux'
                }

              r.foo().should.eventually.deep.equal {
                bar: 'qux'
              }

          it "invalidates received json body with the given type", ->
            r = localRestful (api) ->
              foo: api.get
                receive: api.response types.Boolean
                path: -> '/foo'

            withJsonServer (app) ->
              app.get '/foo', (req, res) ->
                res.json "not a boolean"

              r.foo().should.be.rejected

          it "transparently handles asynchronous jobs", ->
            r = localRestful (api) ->
              foo: api.get
                receive: api.response types.Any
                path: -> '/foo'

            withJsonServer (app) ->
              app.get '/foo', (req, res) ->
                if req.get('x-proxy-request-id') is 123
                  # Backend responds with actual content once job is complete
                  res.json {
                    bar: 'qux'
                  }
                else
                  # Backend acknowledges it has accepted job
                  res.status(202).send { 'request_id': 123 }

              r.foo().should.eventually.deep.equal {
                bar: 'qux'
              }

  describe "Manipulating data in an express REST backend", ->
    CatResource = null
    CatType = null

    CatType = types.Object
      name: types.String
      created: types.Optional types.Boolean

    describe "creating a backend object", ->
      it "results in the object returned by the backend", ->
        withJsonServer (app) ->
          app.post '/cats.json', (req, res) ->
            res.json object:
              created: true
              name: 'hello, this is backend'

          CatResource = localRestful (api) ->
            create: api.post
              send: api.request types.projections.Property 'object'
              path: (id) -> "/cats.json"
              receive: api.response types.Property 'object', CatType

          CatResource.create(name: 'irrelevant').then (cat) ->
            cat.should.have.property('name').equal 'hello, this is backend'
            cat.should.have.property('created').equal true

    describe "uploading a file", ->
      it "sends binary data to a fully specified url", ->
        withJsonServer (app) ->
          CatResource = localRestful (api) ->
            upload: api.upload
              receive: api.response
                201: types.Any

          app.put "/s3/bukkit/image.png", (req, res)->
            form = new formidable.IncomingForm
            form.parse req, (err, fields, files) ->
              res.status(201)
              res.json files
              res.end()

          blob = fs.readFileSync "#{__dirname}/data/kitty.png"
          CatResource.upload("http://localhost:#{port}/s3/bukkit/image.png", blob).then (files) ->
            files.should.have.property 'file'

    describe "when setting request options afterwards", ->

      it "should send headers when getting", ->
        withJsonServer (app) ->
          app.get "/cats/1.json", (req, res)->
            res.json {
              object: req.header("customHeader")
            }

          CatResource = localRestful (api) ->
            find: api.get
              path: (id) -> "/cats/#{id}.json"
              receive: api.response types.Property 'object', types.Any

          customHeader = "random-string-#{Math.random()}"
          CatResource.setOptions headers: { customHeader }

          CatResource.find("1").should.eventually.equal customHeader


      it "should send headers when putting", ->
        withJsonServer (app) ->
          app.put "/cats/1.json", (req, res)->
            res.json {
              object: req.header("customHeader")
            }

          CatResource = localRestful (api) ->
            update: api.put
              send: api.request types.projections.Property 'object'
              path: (id) -> "/cats/#{id}.json"
              receive: api.response types.Property 'object', types.Any

          customHeader = "random-string-#{Math.random()}"
          CatResource.setOptions headers: { customHeader }

          CatResource.update("1", {}).should.eventually.equal customHeader


      it "should send headers when posting", ->
        withJsonServer (app) ->

          app.post "/cats.json", (req, res)->
            res.json {
              object: req.header("customHeader")
            }

          CatResource = localRestful (api) ->
            create: api.post
              send: api.request types.projections.Property 'object'
              path: (id) -> "/cats.json"
              receive: api.response types.Property 'object', types.Any

          customHeader = "random-string-#{Math.random()}"
          CatResource.setOptions headers: { customHeader }

          CatResource.create({name: "garfield"}).should.eventually.equal customHeader


      it "should send headers when deleting", ->
        withJsonServer (app) ->

          app.delete "/cats/1.json", (req, res)->
            res.json {
              object: req.header("customHeader")
            }

          CatResource = localRestful (api) ->
            remove: api.delete
              path: (id) -> "/cats/#{id}.json"
              receive: api.response types.Property 'object', types.Any

          customHeader = "random-string-#{Math.random()}"
          CatResource.setOptions headers: { customHeader }

          CatResource.remove("1").should.eventually.equal customHeader


