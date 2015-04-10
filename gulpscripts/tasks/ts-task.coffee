gulp       = require 'gulp'
$          = require('gulp-load-plugins')()

fs         = require 'fs'
globule    = require 'globule'
merge      = require 'merge2'
Enumerable = require 'linq'
_          = require 'lodash'
defaults   = require 'defaults'

# 外部モジュール化用
dts = require 'dts-bundle'
aem = require '../ambient-external-module'

dbg          = require '../debug/debug'
samePath     = require '../same-path'
errorHandler = require('../notify-error').errorHandler
callback     = require '../gulp-callback'

_createTsModuleRootFile = (out_root) ->
  root_file = "#{out_root}/tsd.d.ts"
  files = globule.find(["#{out_root}/**/*.d.ts", '!' + root_file])
  str = ""
  for x in files
    x = x.replace("#{out_root}/", '') # root_fileからの相対パスへ
    str += "/// <reference path=\"#{x}\" />\n"

  fs.writeFileSync(root_file, str)


_dtsBundleTsModule = (tag, src_root, out_root) ->
  main = tag.file.replace(new RegExp('^' + src_root), "#{out_root}").replace(/.ts$/, '.d.ts')
  dts.bundle(
    name: tag.value
    main: main
    out: main.split('/')[-1..-1][0] # 元のファイル名を渡し、renameしないように
  )

getTsModuleTags = (src_root) ->
  Enumerable.from(aem.collect {root: src_root, include_ext: ['.ts'], exclude_ext: ['.d.ts']})
    .where(aem.isTSFile)
    .where(aem.isAlias)
    .toArray()

_createModuleProject = () ->
  $.typescript.createProject({
    target: "ES6"
    module: "commonjs"
    sortOutput: true
    declarationFiles: true
  })
ts_module_projs = {}

createTsModuleStream = (src_root, out_dts_root, out_js_root, conf) ->
  config = defaults(conf, {
    tags: undefined
  })
  dbg.checkObjectValid(config)

  if (!ts_module_projs[src_root]?)
    ts_module_projs[src_root] = _createModuleProject()

  files = config.tags.map((x) -> x.file)
  ts_proj = ts_module_projs[src_root]
  same_path = samePath(files)

  stream = gulp.src(files, {base: src_root}) # base指定で、階層構造の崩れを無くす
    .pipe($.plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbg.dbgInitSourcemaps())
    .pipe($.typescript ts_proj)

  merge [
    stream.dts
      .pipe(gulp.dest out_dts_root)
      .pipe(callback(() ->
        config.tags.forEach((x) -> _dtsBundleTsModule(x, src_root, out_dts_root)) # 外部モジュール化
        _createTsModuleRootFile(out_dts_root)                    # 外部モジュールのルート定義ファイル作成
      ))

    stream.js
      .pipe(dbg.dbgWriteSourcemaps '.', {
        sourceRoot: '../' + same_path # sourcesから同名のパスが省略されてしまうので、ここで補う
        includeContent: false
      })
      .pipe(gulp.dest out_js_root)
  ]


_createMainProject = () ->
  $.typescript.createProject({
    target: "ES6"
    module: "commonjs"
    sortOutput: true
  })
ts_main_projs = {}

createTsMainStream = (src_root, out_root, conf) ->
  config = defaults(conf, {
    tags: []
  })
  dbg.checkObjectValid(config)


  files = _.difference(
    globule.find(["#{src_root}/**/*.ts", "!#{src_root}/**/*.d.ts"]),
    config.tags.map((x) -> x.file)
  )

  if (!ts_main_projs[src_root]?)
    ts_main_projs[src_root] = _createMainProject()

  ts_proj = ts_main_projs[src_root]
  same_path = samePath(files)

  gulp.src(files, {base: src_root}) # base指定で、階層構造の崩れを無くす
    .pipe($.plumber(
      errorHandler: errorHandler
    ))
    .pipe(dbg.dbgInitSourcemaps())
    .pipe($.typescript ts_proj)
    .js
    .pipe(dbg.dbgWriteSourcemaps '.', {
      sourceRoot: '../' + same_path # sourcesから同名のパスが省略されてしまうので、ここで補う
      includeContent: false
    })
    .pipe(gulp.dest out_root)

# exports ---

module.exports =
  getTsModuleTags: getTsModuleTags
  createTsModuleStream: createTsModuleStream
  createTsMainStream: createTsMainStream
