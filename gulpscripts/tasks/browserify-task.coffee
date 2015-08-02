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

maybeMultiRequire = require 'browserify-maybe-multi-require'
getRequiresFromFiles = require '../get-requires-from-files'

aem             = require '../ambient-external-module'
callback        = require '../gulp-callback'
mergeSourcemaps = require '../merge-multi-sourcemap'
dbg             = require '../debug/debug'
errorHandler    = require('../notify-error').errorHandler

_getAlias = (rawname) ->
  str = rawname.split(':')
  str[1] || str[0]

prev_requires = []
args_requireonly = _.merge(_.cloneDeep(watchify.args), {
  cache: {}
  packageCache: {}
  fullPaths: false
  
  debug: !dbg.is_production
})
browserifyBundleStreamRequireOnly = (lib_root, out_root, conf, bundled_callback) ->
  config = defaults(conf, {
    bundle_name: undefined
    requires: []
  })
  dbg.checkObjectValid(config)
  bundled_callback = bundled_callback || () -> # no-op
    
  dotslash_lib_root = lib_root.replace(/^(\.\/)?/, './')

  entries = globule.find("#{dotslash_lib_root}/**/*.js")
  entry_requires = _(getRequiresFromFiles(entries))
    .intersection(
      config.requires.map(_getAlias)
    )
    .sortBy()
    .value()
  # 必要時だけ再bundle
  if (!_.isEqual(entry_requires, prev_requires))
    prev_requires = entry_requires

    b = browserify(args_requireonly)
    b.plugin(maybeMultiRequire, {
      files: entries
      require: config.requires
    })
    w = watchify(b) # 差分ビルドのみに使う
    b
      .bundle()
      .pipe(source config.bundle_name)
      .pipe(buffer())
      .pipe(dbg.dbgInitSourcemaps {loadMaps: true})
      .pipe(dbg.dbgCompress())
      .pipe(dbg.dbgWriteSourcemaps '.', {
        sourceRoot: '..'
        includeContent: false
      })
      .pipe(gulp.dest out_root)
      .pipe($.duration "browserify #{config.bundle_name} bundle time")
      .pipe(callback(() ->
        # no-op : 元のmoduleはjs前提なので、多段ソースマップの合成は想定していない
      ))
      .pipe(callback bundled_callback)
      .on('end', () ->
        w.close()
      )

args_main = _.merge(_.cloneDeep(watchify.args), {
  cache: {}
  packageCache: {}
  fullPaths: false

  debug: !dbg.is_production
})
browserifyBundleStream = (lib_root, out_root, conf, bundled_callback) ->
  config = defaults(conf, {
    excludes: []
    bundle_name: undefined
  })
  dbg.checkObjectValid(config)
  bundled_callback = bundled_callback || () -> # no-op

  dotslash_lib_root = lib_root.replace(/^(\.\/)?/, './')
  
  # setup
  b = browserify(args_main)
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
  b.plugin(maybeMultiRequire, {
    files: main_files.concat(module_tags.map((x) -> x.file))
    require: ['*']
    external: config.excludes
    ignore: module_tags.map((x) => x.value)
  })
  # bundle
  w = watchify(b) # 差分ビルドのみに使う
  b
    .bundle()
    .on('error', (err) ->
      errorHandler(err)
      this.emit('end')
    )
    .pipe(source config.bundle_name)
    .pipe(buffer())
    .pipe(dbg.dbgInitSourcemaps {loadMaps: true})
    .pipe(dbg.dbgCompress())
    .pipe(dbg.dbgWriteSourcemaps '.', {
      sourceRoot: '..'
      includeContent: false
    })
    .pipe(gulp.dest out_root)
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
    .on('end', () ->
      w.close()
    )

# exports ---

module.exports =
  browserifyBundleStreamRequireOnly: browserifyBundleStreamRequireOnly
  browserifyBundleStream: browserifyBundleStream
