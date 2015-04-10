gulp       = require 'gulp'
$          = require('gulp-load-plugins')()

dbg           = require '../debug/debug'
errorHandler =  require('../notify-error').errorHandler
forkedReactJade = require '../forked-gulp-react-jade'

createReactJadeStream = (src_root, out_root) ->
  gulp.src("#{src_root}/**/*.jade")
    .pipe($.plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbg.dbgInitSourcemaps())
    .pipe(forkedReactJade())
    # Browserifyでbundleしても動くように必要なコードを追加する
    .pipe($.header(
      "var React = require('react');\n" +
      "module.exports = "
    ))
    .pipe($.rename((path) ->
      # gulp-react-jadeで付けられた"-tmpl"を取り除く
      # XXX : 決め打ちなのであまりよろしくない
      path.basename = path.basename.replace(/-tmpl$/, '')
      return
    ))
    .pipe(dbg.dbgWriteSourcemaps '.', {
      sourceRoot: "../#{src_root}" # XXX : out_rootが一階層前提
      includeContent: false
    })
    .pipe(gulp.dest out_root)

# exports ---

module.exports =
  createReactJadeStream: createReactJadeStream
