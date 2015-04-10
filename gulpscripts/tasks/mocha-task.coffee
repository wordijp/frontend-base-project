gulp       = require 'gulp'

browserify = require 'browserify'
fs         = require 'fs'
fse        = require 'fs-extra'
globule    = require 'globule'
source     = require 'vinyl-source-stream'
buffer     = require 'vinyl-buffer'
defaults   = require 'defaults'

dbg             = require '../debug/debug'
callback        = require '../gulp-callback'

cwd = require('process').cwd().replace(/\\/g, '/')

createGetDocumentStream = (out_root, conf) ->
  config = defaults(conf, {
    file_name: undefined
    bundle_name: undefined
    require_name: undefined
  })
  dbg.checkObjectValid(config)

  dotslash_out_root = out_root.replace(/^(\.\/)?/, './')

  # node.js用
  # そのまま使う
  fs.writeFileSync("#{dotslash_out_root}/#{config.file_name}",
    """
    // created by gulpfile
    // get document(for node)
    module.exports = function() {
      var jsdom = require('jsdom').jsdom;
      return jsdom('<html><body></body></html>');
    };
    """
  )

  # ブラウザ用
  # 別bundleとして使う
  tmp = "#{dotslash_out_root}/tmp-#{config.bundle_name}"
  fs.writeFileSync(tmp,
    """
    // created by gulpfile
    // get document(for browser)
    module.exports = function() {
      var $ = require('jquery');
      return $('html');
    };
    """
  )
  b = browserify({debug: !dbg.is_production})
  b.require(tmp, expose: config.require_name)

  b
    .bundle()
    .pipe(source config.bundle_name)
    .pipe(buffer())
    .pipe(dbg.dbgInitSourcemaps {loadMaps: true})
    .pipe(dbg.dbgWriteSourcemaps '.', {
      sourceRoot: '..'
      includeContent: false
    })
    .pipe(gulp.dest out_root)
    .pipe(callback(() ->
      fs.unlinkSync(tmp)
    ))

createRunSourceMapSupport = (src_root, out_root, conf) ->
  config = defaults(conf, {
    is_browser: false
    file_name: undefined
  })
  dbg.checkObjectValid(config)

  dotslash_src_root = src_root.replace(/^(\.\/)?/, './')

  # node用
  files = globule.find(["**/*.js.map"], {srcBase: dotslash_src_root})
  fs.writeFileSync("#{out_root}/#{config.file_name}",
    """

    // created by gulpfile
    #{
      if (config.is_browser)
        "" # no-op NOTE : html側でbrowser-source-map-aupport.jsを読み込む
      else
        "var sourceMapSupport = require('source-map-support');"
    }

    sourceMapSupport.install({
      retrieveSourceMap: function(source) {

        var re = undefined;
        relative = source.replace(/\\\\/g, '/');

        // 相対パスへ
        // NOTE : 各環境を総当たりで対応
        // local(node or browser)
        re = new RegExp('^' + "(file:///)?#{cwd}/");
        relative = relative.replace(re, '');
        // server(normal or secure)
        re = new RegExp('^' + "http(s)?://[^/]+/");
        relative = relative.replace(re, '');

        //console.log("relative :" + relative);

    #{
      # 存在するmapファイル一覧を埋め込む
      files
        .map((map_file) ->
          map_value = fs.readFileSync("#{dotslash_src_root}/#{map_file}").toString().trim()
          js_file = map_file.replace(/\.map$/, '')
          """
          re = new RegExp('^(#{src_root}/)?#{js_file}$');
          if (re.test(relative)) {
            return {
              map: '#{map_value}'
            };
          }
          """
        )
        .join('\n')}

        return null;
      }
    });

    """
  )

# exports ---

module.exports =
  createGetDocumentStream: createGetDocumentStream
  createRunSourceMapSupport: createRunSourceMapSupport
