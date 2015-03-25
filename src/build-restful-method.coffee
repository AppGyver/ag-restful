_ = {
  defaults: require 'lodash-node/modern/objects/defaults'
}

assert = require 'assert-plus'
types = require 'ag-types'
urlify = require './urlify'

module.exports = (http, validations) ->
  # path: (args...) -> url
  # receive: (response) -> Validation data
  # options: () -> Object
  getter: ({path, receive, options}) ->
    assert.func path, 'path'
    assert.func receive, 'receive'
    assert.optionalFunc options, 'options'

    (args...) ->
      # Use the last argument as query params if it's an object
      # Use the rest to create a url
      [head..., tail] = args
      [urlArgs, query] = if typeof tail is 'object'
          [head, tail]
        else
          [args, {}]

      url = path (urlify urlArgs)...

      http
        .request('get', url, _.defaults({query}, options?() || {}))
        .then(validations.validatorToPromised receive)

  # path: (data) -> url
  # send: (data) -> Validation data
  # receive: (response) -> Validation response
  # options: () -> Object
  poster: ({path, send, receive, options}) ->
    assert.func path, 'path'
    assert.func send, 'send'
    assert.func receive, 'receive'
    assert.optionalFunc options, 'options'

    doPostRequest = (data) ->
      url = path (urlify data)
      http.request('post', url, _.defaults({data}, options?() || {}))

    (data) ->
      validations.validationToPromise(send data)
        .then(doPostRequest)
        .then(validations.validatorToPromised receive)

  # path: (args...) -> url
  # options: () -> Object
  # receive: (response) -> Validation data
  deleter: ({path, options, receive}) ->
    assert.func path, 'path'
    assert.optionalFunc options, 'options'
    assert.optionalFunc receive, 'receive'

    (args...) ->
      url = path (urlify args)...
      http
        .request('del', url, options?() || {})
        .then(validations.validatorToPromised (receive || types.Optional(types.Any)))

  # path: (args..., data) -> url
  # send: (data) -> Validation data
  # receive: (response) -> Validation data
  # options: () -> Object
  putter: ({path, send, receive, options}) ->
    assert.func path, 'path'
    assert.func send, 'send'
    assert.func receive, 'receive'
    assert.optionalFunc options, 'options'

    doPutRequest = (args) ->
      url = path (urlify args)...
      (data) ->
        http.request('put', url, _.defaults({data}, options?() || {}))

    (args..., data) ->
      validations.validationToPromise(send data)
        .then(doPutRequest(args))
        .then(validations.validatorToPromised receive)

  # receive: (response) -> Validation data
  uploader: ({receive}) ->
    assert.func receive, 'receive'

    (url, file, options = {}) ->
      http.request(
        'put',
        url,
        _.defaults({
            type: 'application/octet-stream'
            data: switch true
              when Buffer.isBuffer file then file.toString()
              else file
          },
          options || {}
        )
      )
      .then(validations.validatorToPromised receive)
