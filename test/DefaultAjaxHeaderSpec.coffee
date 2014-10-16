express = require "express"
expect = require('chai').expect

types = require 'ag-types'
restful = require '../src/ag/restful'
ajax = require '../src/ag/restful/ajax'

port = 4001

Cat = types.Object
  name: types.String

CatResource = restful {
  baseUrl: "http://localhost:#{port}"
}, (api) ->

  findAll: api.get
    path: -> "/cats"
    receive: api.response types.Property 'objects', types.List Cat

  find: api.get
    path: (id) -> "/cats/#{id}.json"
    receive: api.response types.Property 'object', Cat

  update: api.put
    send: api.request types.projections.Property 'object'
    path: (id) -> "/cats/#{id}.json"
    receive: api.response types.Property 'object', Cat

  create: api.post
    send: api.request types.projections.Property 'object'
    path: (id) -> "/cats"
    receive: api.response types.Property 'object', Cat

  remove: api.delete
    path: (id) -> "/cats/#{id}.json"
    receive: api.response types.Property 'object', Cat


describe "ag-restful.ajax", ->
  app = null
  server = null

  beforeEach ->
    app = express()
    server = app.listen(port)

  afterEach ->
    server.close()

  describe "when setting default headers for ajax requests", ->

    before ->
      ajax.setDefaults headers: {hello: "world"}

    it "should send headers when getting", (done)->
      app.get "/cats/1.json", (req, res)->
        res.json({object: {name: "grafield"}})
        expect(req.header("hello")).to.equal("world")
        done()

      CatResource.find("1")

    it "should send headers when getting all", (done)->
      app.get "/cats", (req, res)->
        res.json({objects: [{name: "garfield"}, {name: "grumpy"}]})
        expect(req.header("hello")).to.equal("world")
        done()

      CatResource.findAll()


    it "should send headers when putting", (done)->
      app.put "/cats/1.json", (req, res)->
        res.json({object: {name: "grafield"}})
        expect(req.header("hello")).to.equal("world")
        done()

      CatResource.update("1", {})


    it "should send headers when posting", (done)->
      app.post "/cats", (req, res)->
        res.json({object: {name: "grafield"}})
        expect(req.header("hello")).to.equal("world")
        done()

      CatResource.create({name: "garfield"})


    it "should send headers when deleting", (done)->
      app.delete "/cats/1.json", (req, res)->
        res.status(200).end()
        done()

      CatResource.remove("1")
