
# 概要

このプロジェクトは、AltJS(TypeScript & CoffeeScript) & Browserify & mocha & React構成の雛形プロジェクトです。

独自拡張として以下の対応をしています。
- require時にaliasを指定出来る
	- 従来の相対パス指定も出来る
- TypeScriptにて、ユーザ外部モジュール及び型定義ファイルの自動生成(import hoge = require(alias名);と書ける)
	- [ソースへのrequire用のalias、ユーザ外部モジュール化について](#alias)
- 多段ソースマップの問題を解決し、Browserify生成のjsファイルからでもAltJSのソースにbreakpointを貼れる
	- [多段ソースマップの解決について](#multi_source_map)
- Reactに対応したmochaによるコンソール、ブラウザ両対応のテスト
	- [mochaのReact対応について](#using_react_for_mocha)
- Watchifyによる自動ビルド時間を極力短縮
	- [bundleファイルの構成について](#about_bundle_file)


また、gulpのbuildやwatch中にエラーが発生するとエラー通知がされるようにしています。

# Usage

1. npm install
2. tsd update -s
3. gulp
  - gulp (build | watch) [--env production]
  - gulp (test | test:watch)
  - gulp clean

--env productionオプションを付けると公開用としてbundleファイルの圧縮を、無しだと開発用としてbundleファイル生成時にソースマップも生成します。
		
# ファイル構成

```
root
├── src - ソース置き場
│   ├── index.html
│   └── scripts
├── test_src - テストソース置き場
│   ├── test.html
│   └── scripts
├── gulpscripts - gulp用の自作スクリプト
│   ├── debug - --env production関係
│   │   └── debug.coffee
│   ├── tasks - 各ビルド関係
│   │   ├── browserify-task.coffee        - Browserifyのbundle処理
│   │   ├── coffee-task.coffee            - CoffeeScriptのトランスパイル処理
│   │   ├── mocha-task.coffee             - mochaのnode用・ブラウザ用各ファイルの生成
│   │   ├── module-task.coffee            - 外部モジュール関係
│   │   ├── react-jade-task.coffee        - react-jadeのトランスパイル処理
│   │   └── ts-task.coffee                - TypeScriptのトランスパイル処理
│   ├── ambient-external-module.coffee - ソース内の専用タグ収集(alias、外部モジュール化の補助)
│   ├── error-log.coffee               - エラーログ
│   ├── forked-gulp-react-jade.coffee  - gulp-react-jadeでエラー発生時にplumberでキャッチ出来るようにしたもの
│   ├── get-file-name.coffee           - パスからファイル名だけ取得
│   ├── grep-sync.coffee               - 同期版のgrep
│   ├── gulp-callback.coffee           - stream内の任意の場所でコールバックを発生させる
│   ├── merge-multi-sourcemap.coffee   - 多段ソースマップの合成
│   ├── notify-error.coffee            - エラーのデスクトップ通知
│   ├── same-path.coffee               - 複数のパスから一致する部分の取得
│   └── to-relative-path.coffee        - パスを相対パスへ
├── gulpfile.coffee - gulpメインスクリプト
├── package.json    - nodeパッケージ
└── tsd.json        - TypeScript型定義ファイルパッケージ
```

また、下記のディレクトリ一覧は自動生成されます

```
root
├── typings          - 公式のDefinitelyTypedによる型定義ファイル(tsd update -sで生成)
├── src_typings      - srcを対象としたユーザ生成型定義ファイル (gulp (build | watch)で生成)
├── test_src_typings - test_srcを対象としたユーザ生成型定義ファイル (gulp (test | test:watch)で生成)
├── public           - src成果物
├── test_public      - test_src成果物
ここからは一時ディレクトリ(無視しても良い)
├── lib
├── lib_tmp
├── src_typings_tmp
├── test_lib
├── test_lib_tmp
└── test_src_typings_tmp

```

# <a name="alias"></a> ソースへのrequire用のalias、ユーザ外部モジュール化について

ソース中に独自タグである
```ts
// TypeScript
/// <ambient-external-module alias="{filename}" />
```

```coffee
# CoffeeScript
###
<ambient-external-module alias="{filename}" />
###
```

を埋め込むことにより、
gulpscripts/ambient-external-module.coffee
がソース中のタグを収集し、browserifyにソースを追加する際にrequireメソッドによりaliasが定義されます

```coffee
b.require('lib/path/to/hoge.js', expose: 'hoge')
```

また、TypeScriptの場合はdts-bundleにより外部モジュール化されsrc_typingsディレクトリ内にユーザ型定義ファイルが作成されるため、

```ts
/// <reference path="root/src_typings/tsd.d.ts" />

import Hoge = require('hoge');
Hoge.foo();
```

という書き方をする事が出来ます。

# <a name="multi_source_map"></a> 多段ソースマップの解決について

AltJSからbrowserifyによるbundleファイル生成までの流れは、以下のようになっています。

- 1.AltJSのトランスパイル
	- hoge.ts -> tsc -> hoge.js & hoge.js.map
	- foo.coffee -> coffee -c -> foo.js & foo.js.map
- 2.browserifyによるbundle
	- (hoge.js & hoge.js.map) & (foo.js & foo.js.map) -> browserify -> bundle.js & bundle.js.map
		
中間ファイルであるhoge.jsやfoo.jsのそれぞれのソースマップファイルはAltJSとの紐づけ、
生成物であるbundle.jsのソースマップファイルは中間ファイルとの紐づけがされた状態であり、
bundle.jsのソースマップファイルから、AltJSへと直接紐づける必要があります。

紐づけ方法ですが、[mozilla/source-map](https://github.com/mozilla/source-map/)によりソースマップ内の対応した位置情報をプロットしてみると、
中間ファイルのソースマップファイルであるhoge.js.mapやfoo.js.mapのgeneratedの位置情報と、
生成物のソースマップファイルであるbundle.js.mapのoriginalの位置情報が対になっていると読み取れます。

![ソースマップのプロット画像](https://github.com/wordijp/altjs-browserify-base-project/blob/master/multi_source_map_prot.png)

この対になっている位置情報を基に、AltJSのoriginalの位置情報と、生成物のbundle.jsのgeneratedの位置情報を取り出せれば、多段ソースマップの問題が解決出来る事になります。

この問題を解決するスクリプトgulpscripts/merge-multi-sourcemap.coffeeを作成し、browserify実行後に走らせることでこの問題を解決しています。
- ※スクリプト内では、さらに細かく紐づけをしています。
- **※browserifyでuglifyによる圧縮後のソースマップに試しましたが、列の位置が微妙にずれる結果となってしまった為、uglifyと併用した場合は上手く動かない可能性があります。**

- 参考)
	- [Source Mapを扱う関連ライブラリのまとめ](http://efcl.info/2014/0622/res3933/)
	- https://github.com/azu/multi-stage-sourcemap
		
# <a name="using_react_for_mocha"></a> mochaのReact対応について


## ファイル構成について

テスト用のjsファイルは、下記の構成になっています。

```
コンソール用
├── get-document.js                   - jsdomによる仮想DOM取得
└── run-source-map-support.js         - source-map-support.js実行時のソースマップ解決

ブラウザ用
├── get-document-bundle.js            - jqueryによるHTML上のDOM取得
└── run-browser-source-map-support.js - browser-source-map-support.js実行時のソースマップ解決

共通
└── test-bundle.js                    - test_srcのソースのbundleファイル
```

コンソール側、ブラウザ側で差異のあるDOM取得処理を別ファイルに切りだし、それぞれの環境で読み込んでいます。

Browserifyのtest-bundle.jsのbundle時、

```
b.exclude('./get-document')
```

とexcludeし、ブラウザ用のget-document-bundle.jsのbundle時に

```
b.require('get-document-bundle.js', expose: './get-document')
```

とrequire名を定義してtest-bundle.jsから見えるようにしています。  
コンソール側では同名となるget-document.jsのままにして、node.js側のrequireを利用するやや裏技的な方法で対処しています。

## run-(browser-)source-map-support.jsについて

多段ソースマップを利用しているため、sourceMapSupport.install()のretrieveSourceMapメソッド内で、各ファイルに対応したソースマップを返す必要があります。

```
sourceMapSupport.install({
  retrieveSourceMap: function(source) {
    if (source === "test-bundle.js") {
	  return test-bundle.js.mapデータ
	}
	...
  }
})
```

このデータは、run-(browser-)source-map-support.jsの生成時にソースマップファイルを読み込んで埋め込む事により対処しています。

# <a name="about_bundle_file"></a> bundleファイルの構成について

bundleファイルは、React等の共通moduleをbundleしたcommon-bundle.jsと、開発時のsrcディレクトリをbundleしたbundle.jsに分けています。

```
public
├── bundle.js        - srcディレクトリのbundle
└── common-module.js - 共通moduleのbundle(React等)
```

開発中にgulp watchを開始し、srcディレクトリのコーディングをした際にbundle.jsだけを自動ビルドの対象とする事で再bundle時間の短縮を図っています。
注意点としてはbundleファイルが複数ある事への認識と、gulpfileのcommon-module.jsに切り出す設定忘れをするとbundle.js側にmoduleが含まれてしまったり、切り出したままにすると未使用の共通moduleがcommon-bundle.js側に含まれてしまう事です。
その為、common-module.jsへと切り出す時は、使用する状態が不変である(ReactでWebサイトを作る場合はReactを必ず使う為、Reactを切り出すのは妥当)moduleを選んだ方が、チーム内でもどれを切り出すべきかの混乱が少なく済みます。

```coffee:gulpfile.coffee
# reactモジュールを、common-bundle.jsへ
gulp.task 'browserify-requireonly', () ->
  browserifyTask.browserifyBundleStreamRequireOnly(['react'], 'public', {bundle_name: 'common-bundle.js'})

# reactモジュールを、bundle.jsへ含めない
createBrowserifyStream = (watching) ->
  browserifyTask.browserifyBundleStream('lib', 'public', {watching: watching, excludes: ['react'], bundle_name: 'bundle.js'})

gulp.task 'browserify', () -> createBrowserifyStream(false)
```

# TypeScriptの定義ファイルについて

定義ファイルは、DefinitelyTypedにより公開されているモジュール用・srcディレクトリ用・test_srcディレクトリ用の3種類があり、
src用、test_src用はgulpで自動生成され、TypeScriptを編集した際にも自動更新されます。

これらはDefinitelyTypedと同様にルート用の定義ファイル(tsd.d.ts)を用意している為、それぞれの定義ファイルを参照するだけでよいです。

- DefinitelyTyped用の定義ファイル
	- typings/tsd.d.ts
		
- srcディレクトリ用の定義ファイル
	- src_typings/tsd.d.ts

- test_srcディレクトリ用の定義ファイル
	- test_src_typings/tsd.d.ts


```ts
/// srcディレクトリの場合
/// <reference path="../../typings/tsd.d.ts" />
/// <reference path="../../src_typings/tsd.d.ts" />
```

```ts
/// test_srcディレクトリの場合
/// <reference path="../../typings/tsd.d.ts" />
/// <reference path="../../test_src_typings/tsd.d.ts" />
```

# Licence

MIT
