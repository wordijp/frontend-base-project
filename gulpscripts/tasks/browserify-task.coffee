gulp       = require 'gulp'
$          = require('gulp-load-plugins')()
source     = require 'vinyl-source-stream'
buffer     = require 'vinyl-buffer'
browserify = require 'browserify'
watchify   = require 'watchify'
_          = require 'lodash'
fs         = require 'fs'
globule    = require 'globule'
Enumerable = require 'linq'

defaults   = require 'defaults'

aem             = require '../ambient-external-module'
callback        = require '../gulp-callback'
mergeSourcemaps = require '../merge-multi-sourcemap'
dbg             = require '../debug/debug'
errorHandler    = require('../notify-error').errorHandler

browserifyBundleStream = (lib_root, out_root, conf, bundled_callback) ->
  config = defaults(conf, {
    watching: false
    excludes: []
    bundle_name: undefined
  })
  dbg.checkObjectValid(config)
  bundled_callback = bundled_callback || () -> # no-op

  args = _.merge(watchify.args, {
    cache: {}
    packageCache: {}
    fullPaths: false

    debug: !dbg.is_production
  })
  b = browserify(args)

  dotslash_lib_root = lib_root.replace(/^(\.\/)?/, './')

  # ソース一式を追加
  module_tags = Enumerable.from(aem.collect {root: dotslash_lib_root, include_ext: ['.js']})
    .where(aem.isAlias)
    .toArray()
  main_files = _.difference(
    globule.find("#{dotslash_lib_root}/**/*.js"),
    module_tags.map((x) -> x.file)
  )
  for x in main_files
    b.add(x)
    b.require(x)
  for x in module_tags
    b.add(x.file)
    b.require(x.file, expose: x.value)
  for x in config.excludes
    b.exclude(x)

  bundle = () ->
    b
      .bundle()
      .on('error', errorHandler)
      .pipe(source "#{config.bundle_name}")
      .pipe(buffer())
      .pipe(dbg.dbgInitSourcemaps {loadMaps: true})
      .pipe(dbg.dbgCompress())
      .pipe(dbg.dbgWriteSourcemaps '.', {
        sourceRoot: '..'
        includeContent: false
      })
      .pipe(gulp.dest out_root) # public
      .pipe($.duration "browserify #{config.bundle_name} bundle time")
      .pipe(callback(() ->
        second_map = "#{out_root}/#{config.bundle_name}.map"

        # 多段ソースマップの合成
        if !dbg.is_production
          timeMsg = "merged #{second_map}"
          console.time(timeMsg)

          second = fs.readFileSync(second_map).toString().trim()

          first_files = globule.find("#{dotslash_lib_root}/**/*.js.map")
          
          second = mergeSourcemaps.merges(
            first_files.map((x) ->
              {value: fs.readFileSync(x).toString().trim(), maproot: lib_root}
            ),
            {value: second, maproot: out_root}
          )

          fs.renameSync(second_map, "#{second_map}.old") # 保存前にオリジナルを退避
          fs.writeFileSync(second_map, second)

          console.timeEnd(timeMsg)
      ))
      .pipe(callback bundled_callback)

  if (config.watching)
    w = watchify(b, {delay: 100})
    w.on('update', bundle)

  bundle()

# exports ---

module.exports =
  browserifyBundleStream: browserifyBundleStream
