Promise = require 'bluebird'
fs = require 'fs'
express = require "express"
bodyparser = require "body-parser"
formidable = require 'formidable'

chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

types = require 'ag-types'
restful = require '../src/ag/restful'

withServerAt = (port, f) ->
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

describe "ag-restful", ->
  describe "Accessing data from a static REST backend", ->
    TaskResource = null
    port = 9001

    withStaticServer = (f) ->
      withServerAt port, (app) ->
        app.use express.static "#{__dirname}/data"
        f(app)

    before ->
      TaskResource = do ->
        TaskType = types.Object
          description: types.String
          created: types.Optional types.Boolean

        return restful {
          baseUrl: "http://localhost:#{port}/task"
        }, (api) ->
          findAll: api.get
            path: -> '/objects.json'
            receive: api.response types.Property 'objects', types.List TaskType

          find: api.get
            path: (id) -> "/objects/#{id}.json"
            receive: api.response types.Property 'object', TaskType

    it "can be done using a user-defined resource", ->
      TaskResource.should.be.defined

    describe "A user-defined TaskResource", ->
      it "can find all tasks", ->
        withStaticServer ->
          TaskResource.findAll().should.eventually.be.an 'array'

      describe "a single task", ->
        it "is an object", ->
          withStaticServer ->
            TaskResource.find('bltc95644acbfe2ca34').should.eventually.be.an 'object'

        it "has a description", ->
          withStaticServer ->
            TaskResource.find('bltc95644acbfe2ca34').should.eventually.have.property('description').equal "take out the trash"

  describe "Manipulating data in an express REST backend", ->
    CatResource = null
    port = 9876
    app = null
    server = null

    beforeEach (done) ->
      app = express()
      app.use bodyparser.json()
      server = app.listen port, done

    afterEach (done) ->
      server.close done

    beforeEach ->
      CatResource = do ->
        CatType = types.Object
          name: types.String
          created: types.Optional types.Boolean

        restful {
          baseUrl: "http://localhost:#{port}"
          headers:
            'a-mandatory-default-header': 'very-important-value'
        }, (api) ->

          find: api.get
            path: (id) -> "/cats/#{id}.json"
            receive: api.response types.Property 'object', CatType

          update: api.put
            send: api.request types.projections.Property 'object'
            path: (id) -> "/cats/#{id}.json"
            receive: api.response types.Property 'object', CatType

          create: api.post
            send: api.request types.projections.Property 'object'
            path: (id) -> "/cats.json"
            receive: api.response types.Property 'object', CatType

          remove: api.delete
            path: (id) -> "/cats/#{id}.json"
            receive: api.response types.Property 'object', CatType

          upload: api.upload
            receive: api.response
              201: types.Any

    describe "creating a backend object", ->
      beforeEach ->
        app.post '/cats.json', (req, res) ->
          res.json object:
            created: true
            name: 'hello, this is backend'

      it "results in the object returned by the backend", ->
        task = CatResource.create(name: 'irrelevant')
        task.should.eventually.have.property('name').equal 'hello, this is backend'
        task.should.eventually.have.property('created').equal true

    describe "uploading a file", ->
      uploadedFiles = null

      beforeEach ->
        uploadedFiles = new Promise (resolve) ->
          app.put "/s3/bukkit/image.png", (req, res)->
            form = new formidable.IncomingForm
            form.parse req, (err, fields, files) ->
              resolve files
              res.status(201).end()
        return # Runner would wait for promise to complete otherwise

      it "sends binary data to a fully specified url", ->
        blob = fs.readFileSync "#{__dirname}/data/kitty.png"
        CatResource.upload("http://localhost:#{port}/s3/bukkit/image.png", blob).should.be.fulfilled
        uploadedFiles.should.eventually.have.property 'file'


    describe "when setting request options afterwards", ->
      customHeader = null

      beforeEach ->
        customHeader = "random-string-#{Math.random()}"
        CatResource.setOptions headers: { customHeader }

      it "should respond to getOptions with defaults plus those that were set", ->
        CatResource.getOptions().headers.should.deep.equal {
          'a-mandatory-default-header': 'very-important-value'
          customHeader: customHeader
        }

      it "should allow overriding headers in default options", ->
        CatResource.setOptions headers: {
          'a-mandatory-default-header': 'an-overriding-value'
        }
        CatResource.getOptions().headers['a-mandatory-default-header'].should.equal 'an-overriding-value'

      it "should revert back to defaults after removing overriding header", ->
        CatResource.setOptions headers: {
          'a-mandatory-default-header': 'an-overriding-value'
          foo: 'bar'
        }
        CatResource.setOptions {}
        CatResource.getOptions().headers.should.deep.equal {
          'a-mandatory-default-header': 'very-important-value'
        }

      it "should send headers when getting", (done)->

        app.get "/cats/1.json", (req, res)->
          res.json({object: {name: "grafield"}})
          req.header("customHeader").should.equal customHeader
          done()

        CatResource.find("1")


      it "should send headers when putting", (done)->
        app.put "/cats/1.json", (req, res)->
          res.json({object: {name: "grafield"}})
          req.header("customHeader").should.equal customHeader
          done()

        CatResource.update("1", {})


      it "should send headers when posting", (done)->
        app.post "/cats.json", (req, res)->
          res.json({object: {name: "grafield"}})
          req.header("customHeader").should.equal customHeader
          done()

        CatResource.create({name: "garfield"})


      it "should send headers when deleting", (done)->
        app.delete "/cats/1.json", (req, res)->
          res.status(200).end()
          req.header("customHeader").should.equal customHeader
          done()

        CatResource.remove("1")


