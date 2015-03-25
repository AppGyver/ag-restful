superagent = require 'superagent'
###
(
  method: String
  path: String
  options: Object?
) -> superagent
###
module.exports = buildRequest = (method, path, options = {}) ->
  if !superagent[method]?
    throw new Error "No such request builder method: #{method}"

  requestBuilder = superagent[method](
    if options.baseUrl?
      [options.baseUrl, path].join ''
    else
      path
  )

  if options.headers
    for header, value of options.headers || {}
      requestBuilder.set header, value

  if options.query
    requestBuilder.query options.query

  if options.type?
    requestBuilder.type options.type

  if options.accept?
    requestBuilder.accept options.accept

  # Accept multipart data for file uploads
  if options.parts?
    for part in options.parts
      partBuilder = requestBuilder.part()
      for header, value of part.headers || {}
        partBuilder.set header, value
      if part.data?
        partBuilder.write part.data
  else if options.data?
    requestBuilder.send options.data

  # If buffer() is defined on requestBuilder, we can explicitly request buffering
  if options.buffer && requestBuilder.buffer?
    requestBuilder.buffer()

  requestBuilder
