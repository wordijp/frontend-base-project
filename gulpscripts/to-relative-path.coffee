# プロジェクト内の絶対パスを相対パスへ

cwd = require('process').cwd().replace(/\\/g, '/')
re = new RegExp('^' + cwd + '/')

module.exports = (path) ->
  path.replace(/\\/g, '/').replace(re, '')
