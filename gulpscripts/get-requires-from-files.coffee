_  = require 'lodash'
fs = require 'fs'

astRequireParser = require('./ast-parser').astRequireParser

# requireしているmodule一覧を読み込み、返す
getRequiresFromFiles = (files) ->
  requires = []
  for x in files
    data = fs.readFileSync(x)
    astRequireParser(data, (require) ->
      requires.push(require)
    )
  _.uniq(requires)

module.exports = getRequiresFromFiles
