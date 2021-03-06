merge = require 'lodash-node/modern/object/merge'
deepDefaults = require './options/deep-defaults'

module.exports = (buildRestful, validateResponseBody) ->
  ###
  (defaultRequestOptions: { baseUrl?: String, headers?: Object })
  -> {
    get, post, delete, put, response, request
  }
  ###
  restMethodBuilder = (defaultRequestOptions) ->
    currentOptions = defaultRequestOptions || {}

    withOptions = (resourceBuilder) -> (resourceDescription) ->
      resourceBuilder deepDefaults resourceDescription, {
        options: -> currentOptions
      }

    getOptions: ->
      currentOptions

    setOptions: (options) ->
      currentOptions = deepDefaults options, defaultRequestOptions
      currentOptions

    get: withOptions buildRestful.getter
    post: withOptions buildRestful.poster
    delete: withOptions buildRestful.deleter
    put: withOptions buildRestful.putter
    # NOTE: No default options applied
    upload: buildRestful.uploader

    response: validateResponseBody
    request: (projection) -> (data) ->
      # Double-underscored properties are sikrits and not data
      # Stash sikrits away
      sikrits = {}
      for key, value of data when 0 is key.indexOf '__'
        continue if key is '__appgyver_acl'
        sikrits[key] = value
        delete data[key]

      projection(data).map (requestBody) ->
        # Merge sikrits back in to the request body root
        merge {}, requestBody, sikrits

  # (
  #  defaultRequestOptions: { baseUrl?: String, headers?: Object },
  #  doSetup: ({
  #    get, post, delete, put, response, request
  #  }) -> Object
  # ) -> Object
  return buildRestfulObject = (defaultRequestOptions, doSetup) ->
    builder = restMethodBuilder defaultRequestOptions
    restfulObject = doSetup builder

    # Amend object with setter and getter for options unless the setup already included them
    restfulObject.getOptions ?= builder.getOptions
    restfulObject.setOptions ?= builder.setOptions

    restfulObject
