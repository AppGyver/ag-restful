jsc = require 'jsverify'

mapGenerator = (arb, f) ->
  {
    generator: arb.generator.map f
    shrink: arb.shrink
    show: arb.show
  }

module.exports = {
  mapGenerator
}
