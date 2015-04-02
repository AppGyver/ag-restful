partialRight = require 'lodash-node/modern/function/partialRight'
merge = require 'lodash-node/modern/object/merge'
isArray = require 'lodash-node/modern/lang/isArray'
isDate = require 'lodash-node/modern/lang/isDate'

###
Recursive version of _.defaults

See: https://github.com/balderdashy/merge-defaults

Inlined here because the repo linked has a hard dependency on the 'lodash' module.
###
recursiveDefaults = (left, right) ->
  # Ensure dates and arrays are not recursively merged
  if isArray(left) or isDate(left)
    left
  else
    merge left, right, recursiveDefaults

module.exports = deepDefaults = partialRight merge, recursiveDefaults
