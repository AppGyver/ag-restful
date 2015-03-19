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
  describe "Manipulating data in an express REST backend", ->
    CatResource = null
    CatType = null
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

    describe "getOptions", ->
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


      it.skip "should send headers when deleting", ->
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


