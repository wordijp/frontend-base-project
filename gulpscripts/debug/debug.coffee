
$ = require('gulp-load-plugins')()
errLog = require '../error-log'

is_production = require('yargs').argv.env is "production"
console.log("--env production : " + is_production)

dbgCompress        = ()           -> if is_production then $.uglify() else $.util.noop()
dbgInitSourcemaps  = (prop)       -> if is_production then $.util.noop() else $.sourcemaps.init(prop)
dbgWriteSourcemaps = (path, prop) -> if is_production then $.util.noop() else $.sourcemaps.write(path, prop)

checkObjectValid = (obj) ->
  for x of obj
    if (!obj[x]?)
      errLog("#{x} is undefined")

# exports ---

module.exports =
  is_production: is_production

  dbgCompress: dbgCompress
  dbgInitSourcemaps: dbgInitSourcemaps
  dbgWriteSourcemaps: dbgWriteSourcemaps
  
  checkObjectValid: checkObjectValid
