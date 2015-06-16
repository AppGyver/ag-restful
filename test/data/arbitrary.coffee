jsc = require 'jsverify'

arbitraryHttpMethod = jsc.elements ['get', 'post', 'put', 'del']

arbitraryOptions = jsc.record {
  headers: jsc.dict(jsc.oneof(jsc.string, jsc.bool, jsc.number))
  query: jsc.dict(jsc.oneof(jsc.string, jsc.bool, jsc.number))
}

module.exports = {
  httpMethod: arbitraryHttpMethod
  requestOptions: arbitraryOptions
}
