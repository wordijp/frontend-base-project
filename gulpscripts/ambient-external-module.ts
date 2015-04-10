// ambient external module script
//
// ソースに専用タグを付与し、それぞれのタグ収集を行います
//
// usage)
//   ディレクトリ構成と、ソースファイル内の専用タグが下記のようになっているとします
//   - src
//     - moduleA.ts     : /// <ambient-external-module name='moduleA' />
//     - moduleB.coffee : /// <ambient-external-module name='{filename}' />
//     - hogedir
//       - moduleC.ts   : /// <ambient-external-module alias='moduleC' />
//
//   aem = require('./ambient-external-module')
//   config =
//      root: 'src'
//      include_ext: ['.ts', '.coffee']
//      exclude_ext: ['.d.ts']
//   tags = aem.collect config
//   とタグを収集すると
//
//   [
//     {
//       file: 'src/moduleA.ts'
//       type: 'name'
//       value: 'moduleA'
//     },
//     {
//       file: 'src/moduleB.coffee'
//       type: 'name'
//       value: 'moduleB'
//     },
//     {
//       file: 'src/hogedir/moduleC.ts'
//       type: 'alias'
//       value: 'moduleC'
//     }
//   ]
//   という結果が返ります
//   あとは、この結果を、webpackやdts-bundle使用時に必要な結果を取り出して使用します

/// <reference path="../typings/tsd.d.ts" />

var gutil      = require('gulp-util');
var globule    = require('globule');
var Enumerable = require('linq');
var defaults   = require('defaults');

var errLog   = require('./error-log');
var grepSync = require('./grep-sync');

var tag_name = 'ambient-external-module';

// tag内の要素が、引数と一致するか
var isKeyValue = (tag:any, key_key:string, key_value:string | RegExp) => { return tag[key_key].match(key_value) != null }

// タグ内の{}プロパティ内の変換処理
var propertyParsers =
  {
    // ファイルパスから拡張子無しのファイル名を取り出す
    filename: (filepath:string) => {
      var str = filepath.split('/').slice(-1)[0];
      return str.split('.')[0] // 拡張子無しへ
	},

    // ファイルパスからディレクトリ名を取り出す
    dirname: (filepath:string) => { return filepath.split('/').slice(-2, -1)[0]; }
  }

// タグ情報をオブジェクトで返す
var toTagObject = (file:string, type:string, value:string) => {
  return {
    file: file,
    type: type,
    value: value,
  };
}

// プロパティを含むvalue_strを展開する
var parseValues = (value_str:string, file:string) => {
  var value = "";
  // 文字列を、プロパティか、プロパティでないかに分解する
  // ex) '{dirname].{filename}' -> ['{dirname}, '.', '{filename}]
  value_str.match(/((\{[^\{\}]+\})|([^\{\}]+))/g).forEach((x) => {
    var matched = x.match(/\{(.+)\}/);

    // プロパティの場合
    if (matched) {
      var prop = matched[1];
      if (propertyParsers[prop] != null) {
        value += propertyParsers[prop](file);
	  }
      else {
        errLog("unknown property:" + prop + " file:" + file);
	  }
	}
    // プロパティ以外の場合
    else {
      value += x;
	}
  });

  return value;
}

var obj = {
  // プロジェクト内のソースからタグを収集し、返す
  collect: (conf) => {
    // 未定義の時はDefault値
    var config = defaults(conf, {
      root: 'src',
      include_ext: ['.ts', '.coffee'],
      exclude_ext: ['.d.ts']
    });

    // プロジェクト内のソースを収集
    var includes = config.include_ext.map((x) => { return config.root + '/**/*' + x; });
    var excludes = config.exclude_ext.map((x) => { return '!' + config.root + '/**/*' + x; });
    var files = globule.find(includes.concat(excludes));

    // ファイルからタグ一覧を収集する
    var tags = Enumerable.from(files)
      .select((file) => {
        var ret = grepSync(['-w', tag_name, file]);
        if (!ret) {
          return {};
		}

        var type_value = ret.split(tag_name)[1].trim();
        var split = type_value.split('=');
        var type  = split[0];
        var value = split[1];

        // value内の文字列を取り出す
        var matched = value.match(/[\"\'](.+)[\"\']/);
        if (!matched) {
          errLog("failed to value.match file:" + file);
          return {};
		}

        var parsed_value = parseValues(matched[1], file);
        return toTagObject(file, type, parsed_value);
	  })
      .where((obj) => { return Object.keys(obj).length > 0; })
      .toArray();

    //console.log("-----------------------");
    //console.log("tags:");
    //console.log(tags);
    //console.log("-----------------------");

    return tags;
  },

  // filtering methods ---

  isAlias:  (tag) => { return isKeyValue(tag, 'type', 'alias'); },
  isName:   (tag) => { return isKeyValue(tag, 'type', 'name'); },
  isTSFile: (tag) => { return isKeyValue(tag, 'file', /.ts$/); }
};
export = obj;
