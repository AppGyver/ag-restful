mapValues = require 'lodash-node/modern/objects/mapValues'

###
Make sure that all scalar values in an input object graph are encoded and ready to be output in a URL
###
module.exports = urlify = (input) ->
  return '' unless input?

  switch (Object::toString.call input)
    when '[object Object]' then mapValues input, urlify
    when '[object Array]' then (urlify item for item in input)
    else encodeURIComponent input
