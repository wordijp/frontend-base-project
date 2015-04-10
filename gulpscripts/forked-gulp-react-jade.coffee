# gulp-react-jadeを、plumberでキャッチ出来るようにしたもの
# original) https://www.npmjs.com/package/gulp-react-jade

path        = require('path')
util        = require('util')
through2    = require('through2')
gutil       = require('gulp-util')
reactJade   = require('react-jade')
PluginError = gutil.PluginError

module.exports = (options) ->
  through2.obj((file, enc, cb) ->
    if (file.isNull())
      return cb(null, file)

    if (file.isStream())
      return cb(new PluginError('gulp-react-jade', 'Streaming not supported'))

    str = file.contents.toString('utf8')

    try
      react = reactJade.compile(str)
    catch e
      return cb(new PluginError('gulp-react-jade', e.message))

    if (options && options.amd)
      react = 'define(function() { return ' + react + '; });'

    file.contents = new Buffer(react.toString())
    file.path = gutil.replaceExtension(file.path, '-tmpl.js')

    cb(null, file)
  )

