# 同期版grep

spawnSync = require('child_process').spawnSync
errLog    = require './error-log'

module.exports = (args) ->
  sync = spawnSync('grep', [].concat(args))
  if (sync.stderr.length > 0)
    errLog(sync.status)
    errLog(sync.stdout)
    errLog(sync.stderr)
    return ""

  sync.stdout.toString().trim()
