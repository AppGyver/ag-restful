chai = require('chai')
chai.use(require 'chai-as-promised')
chai.should()

types = require 'ag-types'
restful = require('../src')(require 'bluebird')

withServer = require './with-server'
express = require 'express'

describe "ag-restful", ->
  describe "Accessing data from a static REST backend", ->
    TaskResource = null
    port = 9001

    withStaticServer = (f) ->
      withServer (app) ->
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
