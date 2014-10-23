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

describe "ag-restful", ->
  describe "Accessing data from a static REST backend", ->
    TaskResource = null

    port = 9001
    app = null
    server = null

    beforeEach (done) ->
      app = express()
      app.use express.static "#{__dirname}/data"
      server = app.listen port, done

    afterEach (done) ->
      server.close done

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
        TaskResource.findAll().then (tasks) ->
          tasks.should.be.an.array

      describe "a single task", ->
        sampleTask = null

        beforeEach ->
          TaskResource.find('bltc95644acbfe2ca34').then (task) ->
            sampleTask = task

        it "is an object", ->
          sampleTask.should.be.an.object

        it "has a description", ->
          sampleTask.should.have.property('description').equal "take out the trash"

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

