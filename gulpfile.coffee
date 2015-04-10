# NOTE : gulpfileに書いとくだけで良い
require('typescript-require')     # 他言語からTypeScriptファイルのrequireを可能にする
require('coffee-script/register') # 他言語からCoffeeScriptファイルのrequireを可能にする

gulp        = require 'gulp'
$           = require('gulp-load-plugins')()
runSequence = require 'run-sequence'
streamqueue = require 'streamqueue'

del        = require 'del'
fs         = require 'fs'
fse        = require 'fs-extra'

notifyError    = require('./gulpscripts/notify-error').notifyError
errorHandler   = require('./gulpscripts/notify-error').errorHandler
toRelativePath = require './gulpscripts/to-relative-path'
getFileName    = require './gulpscripts/get-file-name'

tsTask         = require './gulpscripts/tasks/ts-task'
coffeeTask     = require './gulpscripts/tasks/coffee-task'
browserifyTask = require './gulpscripts/tasks/browserify-task'
mochaTask      = require './gulpscripts/tasks/mocha-task'
moduleTask     = require './gulpscripts/tasks/module-task'
reactJadeTask  = require './gulpscripts/tasks/react-jade-task'

cwd = require('process').cwd().replace(/\\/g, '/')
npm_bin = "#{cwd}/node_modules/.bin"

# ---------------
# build tasks ---

gulp.task 'check:rename-module', () ->
  moduleTask.checkRenameModule('src', () ->
    notifyError('check:rename-module', 'please restart gulp') # browserifyのrequireの再設定が必要
  )

gulp.task 'clean:src', (cb) -> del(['public', 'lib', 'lib_tmp', 'src_typings', 'src_typings_tmp', 'tmp'], cb)

gulp.task 'mkdir', () ->
  if (!fs.existsSync('src_typings'))
    fs.mkdir('src_typings')
  if (!fs.existsSync('src_typings_tmp'))
    fs.mkdir('src_typings_tmp')

# build task
gulp.task 'build:lib', ['build:ts', 'build:coffee', 'build:cjsx', 'build:react-jade', 'build:html']

# ts build task
gulp.task 'pre-build:ts', () ->
  tags = tsTask.getTsModuleTags('src')

  # ファンクタを渡せるのを利用した遅延評価
  # NOTE : module作成後に各処理を開始する必要がある

  streamqueue({objectMode: true},
    tsTask.createTsModuleStream('src', 'src_typings_tmp', 'lib_tmp', {tags: tags})
      .pipe($.duration 'ts module build time'),
    () ->
      # 一端tmpに作って、IDE等の再読み込みと被らないようにしていたのを適用
      gulp.src('src_typings_tmp/**/*.*')
        .pipe($.changed 'src_typings', {hasChanged: $.changed.compareSha1Digest})
        .pipe(gulp.dest 'src_typings')
    ,
    () ->
      tsTask.createTsMainStream('src', 'lib_tmp', {tags: tags})
        .pipe($.duration 'ts main build time')
  )

gulp.task 'build:ts', ['pre-build:ts'], () ->
  gulp.src('lib_tmp/**/*.*')
    .pipe(gulp.dest 'lib') # watchifyへの通知も兼ねる

# coffee build task
gulp.task 'build:coffee', () -> coffeeTask.createCoffeeStream('src', 'lib')

gulp.task 'build:cjsx', () -> coffeeTask.createCjsxStream('src', 'lib')

# react jade build task
gulp.task 'build:react-jade', () -> reactJadeTask.createReactJadeStream('src', 'lib')

# html build task
gulp.task 'build:html', () ->
  gulp.src('src/**/*.html')
    .pipe(gulp.dest 'public')

# browserify task
createBrowserifyStream = (watching) -> browserifyTask.browserifyBundleStream('lib', 'public', {watching: watching, bundle_name: 'bundle.js'})

gulp.task 'browserify', () -> createBrowserifyStream(false)
gulp.task 'watchify',   () -> createBrowserifyStream(true)

# ----------------
# public tasks ---

gulp.task 'build',     (cb) -> runSequence('clean:src', 'mkdir', 'build:lib', 'browserify', cb)

gulp.task 'pre-watch', (cb) -> runSequence('clean:src', 'mkdir', 'build:lib', 'watchify', cb)
gulp.task 'watch', ['pre-watch'], () ->
  # changed watch
  changedWatch = (watch_files, task_name) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'changed')
        runSequence(task_name)
    )
  changedWatch(['src/**/*.ts', '!src/**/*.d.ts'], ['check:rename-module' , 'build:ts'])
  changedWatch('src/**/*.coffee'                , ['check:rename-module' , 'build:coffee'])
  changedWatch('src/**/*.cjsx'                  , ['check:rename-module' , 'build:cjsx'])
  changedWatch('src/**/*.jade'                  , ['build:react-jade'])
  changedWatch('src/**/*.html'                  , ['build:html'])

  # (add | unlink) watch
  addOrUnlinkWatch = (watch_files, cb) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'added' or e.type is 'deleted')
        cb(e)
    )
  addOrUnlinkWatch [
    'src/**/*.ts'
    'src/**/*.coffee'
    'src/**/*.cjsx'
    'src/**/*.jade'
  ], (e) ->
    notifyError('add or unlink', 'please restart gulp', toRelativePath(e.path) + " is " + e.type) # browserifyのadd、requireの再設定が必要


gulp.task 'clean', ['clean:src', 'clean:test']

gulp.task 'default', () ->
  console.log """
    usage) gulp (build | watch) [--env production]
           gulp (test | test:watch)
           gulp clean
  """

# --------------------
# build test tasks ---

gulp.task 'check:test-rename-module', () ->
  moduleTask.checkRenameModule('test_src', () ->
    notifyError('check:test-rename-module', 'please restart gulp (test)') # browserifyのrequireの再設定が必要
  )

gulp.task 'mkdir:test', () ->
  if (!fs.existsSync('test_src_typings'))
    fs.mkdir('test_src_typings')
  if (!fs.existsSync('test_src_typings_tmp'))
    fs.mkdir('test_src_typings_tmp')

gulp.task 'clean:test', (cb) -> del(['test_public', 'test_lib', 'test_lib_tmp', 'test_src_typings', 'test_src_typings_tmp'], cb)

# build task
gulp.task 'build:test-lib', ['build:test-ts', 'build:test-coffee', 'build:test-cjsx', 'build:test-react-jade', 'build:test-html']

# ts build task
gulp.task 'pre-build:test-ts', () ->
  tags = tsTask.getTsModuleTags('test_src')

  # ファンクタを渡せるのを利用した遅延評価
  # NOTE : module作成後に各処理を開始する必要がある
  streamqueue({objectMode: true},
    tsTask.createTsModuleStream('test_src', 'test_src_typings_tmp', 'test_lib_tmp', {tags: tags})
      .pipe($.duration 'ts test module build time'),
    () ->
      # 一端tmpに作って、IDE等の再読み込みと被らないようにしていたのを適用
      gulp.src('test_src_typings_tmp/**/*.*')
        .pipe($.changed 'test_src_typings', {hasChanged: $.changed.compareSha1Digest})
        .pipe(gulp.dest 'test_src_typings')
    ,
    () ->
      tsTask.createTsMainStream('test_src', 'test_lib_tmp', {tags: tags})
        .pipe($.duration 'ts test main build time')
  )

gulp.task 'build:test-ts', ['pre-build:test-ts'], () ->
  gulp.src('test_lib_tmp/**/*.*')
    .pipe(gulp.dest 'test_lib') # watchifyへの通知も兼ねる

# coffee build task
gulp.task 'build:test-coffee', () -> coffeeTask.createCoffeeStream('test_src', 'test_lib')

gulp.task 'build:test-cjsx', () -> coffeeTask.createCjsxStream('test_src', 'test_lib')

# react jade build task
gulp.task 'build:test-react-jade', () -> reactJadeTask.createReactJadeStream('test_src', 'test_lib')

# html build task
gulp.task 'build:test-html', () ->
  gulp.src('test_src/**/*.html')
    .pipe(gulp.dest 'test_public')

# test browserify task
createTestBrowserifyStream = (watching) ->
  browserifyTask.browserifyBundleStream('test_lib', 'test_public', {watching: watching, excludes: ['./get-document'], bundle_name: 'test-bundle.js'}, () ->

    # require is mocha tasks
    mochaTask.createRunSourceMapSupport('test_public', 'test_public', {is_browser: false, file_name: 'run-source-map-support.js'})
    mochaTask.createRunSourceMapSupport('test_public', 'test_public', {is_browser: true, file_name: 'run-browser-source-map-support.js'})

    $.util.log("created run-source-map-support")
  )

gulp.task 'test:watchify', () -> createTestBrowserifyStream(true)
gulp.task 'test:browserify', () -> createTestBrowserifyStream(false)

# mocha task(for node)
gulp.task 'create:get-document', () ->
  mochaTask.createGetDocumentStream('test_public', {file_name: 'get-document.js', bundle_name: 'get-document-bundle.js', require_name: './get-document'})

gulp.task 'test:mocha', () ->
  gulp.src([
   "./test_public/run-source-map-support.js"
   "./test_public/test-bundle.js"
   "./test_public/get-document.js"
  ])
    .pipe($.plumber(
      errorHandler: errorHandler
    ))
    .pipe($.mocha(
      reporter: 'nyan'
    ))

# mocha task(for browser)
gulp.task 'pre-test:livereload', () ->
  # 必要なmoduleをnode_modulesから直接コピー
  # NOTE : package.jsonが正しく無い為にresolveやbrowser-resolveでは取得できないファイルがある為、
  #        直接の方が手っ取り早い
  modules = [
    'node_modules/source-map-support/browser-source-map-support.js'
    'node_modules/jquery/dist/jquery.js'
    'node_modules/mocha/mocha.js'
    'node_modules/mocha/mocha.css'
  ]
  for x in modules
    fse.copySync(x, "test_public/lib/#{getFileName(x)}")

gulp.task 'test:livereload', ['pre-test:livereload'], () ->
  gulp.src('test_public')
    .pipe($.webserver(
      livereload: true
      open: 'test.html'
    ))

# ---------------------
# public test tasks ---

gulp.task 'test',           (cb) -> runSequence('clean:test', 'mkdir:test', 'build:test-lib', 'create:get-document', 'test:browserify', 'test:mocha', cb)

gulp.task 'pre-test:watch', (cb) -> runSequence('clean:test', 'mkdir:test', 'build:test-lib', 'create:get-document', 'test:watchify', ['test:mocha', 'test:livereload'], cb)
gulp.task 'test:watch', ['pre-test:watch'], () ->

  console.log('**********************************')
  console.log('** already starting gulp watch? **') # gulp watchは別consoleにしてログを分けた方が見やすい
  console.log('**********************************')

  # changed watch
  changedWatch = (watch_files, task_name) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'changed')
        runSequence(task_name)
    )
  changedWatch ['test_src/**/*.ts', '!test_src/**/*.d.ts'], ['check:test-rename-module', 'build:test-ts']
  changedWatch 'test_src/**/*.cjsx'                       , ['check:test-rename-module', 'build:test-cjsx']
  changedWatch 'test_src/**/*.coffee'                     , ['check:test-rename-module', 'build:test-coffee']
  changedWatch 'test_src/**/*.jade'                       , ['build:test-react-jade']
  changedWatch 'test_src/**/*.html'                       , ['build:test-html']
  $.watch('test_public/run-source-map-support.js'         , () -> runSequence(['test:mocha'])) # gulp-watchの方が反応が良い

  # (add | unlink) watch
  addOrUnlinkWatch = (watch_files, cb) ->
    watcher = gulp.watch(watch_files)
    watcher.on('change', (e) ->
      if (e.type is 'added' or e.type is 'deleted')
        cb(e)
    )
  addOrUnlinkWatch [
    'test_src/**/*.ts'
    'test_src/**/*.coffee'
    'test_src/**/*.cjsx'
    'test_src/**/*.jade'
  ], (e) ->
    notifyError('add or unlink', 'please restart gulp', toRelativePath(e.path) + " is " + e.type) # browserifyのadd、requireの再設定が必要

