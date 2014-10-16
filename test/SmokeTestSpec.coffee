require('chai').should()

describe "ag-restful root", ->
  it "should be defined", ->
    require('../src/ag/restful').should.exist