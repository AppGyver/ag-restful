jsc = require 'jsverify'

arbitraryHttpMethod = jsc.elements ['get', 'post', 'put', 'del']

isAlnumString = (string) ->
  !!(string.match /^[a-zA-Z0-9]+$/)

arbitraryKeyString = jsc.bless jsc.suchthat jsc.asciinestring, isAlnumString

arbitraryKeyValuePair = jsc.pair(arbitraryKeyString, jsc.oneof(jsc.string, jsc.bool, jsc.number)).smap(
  ([key, value]) ->
    object = {}
    object[key] = value
    object
  (object) ->
    for key, value of object
      return [key, value]
    [null, null]
)

arbitraryOptions = jsc.record {
  headers: arbitraryKeyValuePair
  query: arbitraryKeyValuePair
}

module.exports = {
  httpMethod: arbitraryHttpMethod
  requestOptions: arbitraryOptions
}
