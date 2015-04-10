gulp       = require 'gulp'
$          = require('gulp-load-plugins')()
defaults   = require 'defaults'

dbg           = require '../debug/debug'
errorHandler =  require('../notify-error').errorHandler

_createStream = (src_root, out_root, conf) ->
  config = defaults(conf, {
    ext: undefined
    compiler: undefined
  })
  dbg.checkObjectValid(config)

  gulp.src("#{src_root}/**/*#{config.ext}")
    .pipe($.plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbg.dbgInitSourcemaps())
    .pipe(config.compiler())
    .pipe(dbg.dbgWriteSourcemaps '.', {
      sourceRoot: "../#{src_root}" # XXX : out_rootが一階層前提
      includeContent: false
    })
    .pipe(gulp.dest out_root)

createCoffeeStream = (src_root, out_root) -> _createStream(src_root, out_root, {ext: '.coffee', compiler: $.coffee})
createCjsxStream   = (src_root, out_root) -> _createStream(src_root, out_root, {ext: '.cjsx', compiler: $.coffeeReact})

# exports ---

module.exports =
  createCoffeeStream: createCoffeeStream
  createCjsxStream: createCjsxStream
