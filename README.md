
# �T�v

���̃v���W�F�N�g�́AAltJS(TypeScript & CoffeeScript) & Browserify & mocha & React�\���̐��`�v���W�F�N�g�ł��B

�Ǝ��g���Ƃ��Ĉȉ��̑Ή������Ă��܂��B
- require����alias���w��o����
	- �]���̑��΃p�X�w����o����
- TypeScript�ɂāA���[�U�O�����W���[���y�ь^��`�t�@�C���̎�������(import hoge = require(alias��);�Ə�����)
	- [�\�[�X�ւ�require�p��alias�A���[�U�O�����W���[�����ɂ���](#alias)
- ���i�\�[�X�}�b�v�̖����������ABrowserify������js�t�@�C������ł�AltJS�̃\�[�X��breakpoint��\���
	- [���i�\�[�X�}�b�v�̉����ɂ���](#multi_source_map)
- React�ɑΉ�����mocha�ɂ��R���\�[���A�u���E�U���Ή��̃e�X�g
	- [mocha��React�Ή��ɂ���](#using_react_for_mocha)
- Watchify�ɂ�鎩���r���h���Ԃ��ɗ͒Z�k
	- [bundle�t�@�C���̍\���ɂ���](#about_bundle_file)


�܂��Agulp��build��watch���ɃG���[����������ƃG���[�ʒm�������悤�ɂ��Ă��܂��B

# Usage

1. npm install
2. tsd update -s
3. gulp
  - gulp (build | watch) [--env production]
  - gulp (test | test:watch)
  - gulp clean

--env production�I�v�V������t����ƌ��J�p�Ƃ���bundle�t�@�C���̈��k���A�������ƊJ���p�Ƃ���bundle�t�@�C���������Ƀ\�[�X�}�b�v���������܂��B
		
# �t�@�C���\��

```
root
������ src - �\�[�X�u����
��   ������ index.html
��   ������ scripts
������ test_src - �e�X�g�\�[�X�u����
��   ������ test.html
��   ������ scripts
������ gulpscripts - gulp�p�̎���X�N���v�g
��   ������ debug - --env production�֌W
��   ��   ������ debug.coffee
��   ������ tasks - �e�r���h�֌W
��   ��   ������ browserify-task.coffee        - Browserify��bundle����
��   ��   ������ coffee-task.coffee            - CoffeeScript�̃g�����X�p�C������
��   ��   ������ mocha-task.coffee             - mocha��node�p�E�u���E�U�p�e�t�@�C���̐���
��   ��   ������ module-task.coffee            - �O�����W���[���֌W
��   ��   ������ react-jade-task.coffee        - react-jade�̃g�����X�p�C������
��   ��   ������ ts-task.coffee                - TypeScript�̃g�����X�p�C������
��   ������ ambient-external-module.coffee - �\�[�X���̐�p�^�O���W(alias�A�O�����W���[�����̕⏕)
��   ������ error-log.coffee               - �G���[���O
��   ������ forked-gulp-react-jade.coffee  - gulp-react-jade�ŃG���[��������plumber�ŃL���b�`�o����悤�ɂ�������
��   ������ get-file-name.coffee           - �p�X����t�@�C���������擾
��   ������ grep-sync.coffee               - �����ł�grep
��   ������ gulp-callback.coffee           - stream���̔C�ӂ̏ꏊ�ŃR�[���o�b�N�𔭐�������
��   ������ merge-multi-sourcemap.coffee   - ���i�\�[�X�}�b�v�̍���
��   ������ notify-error.coffee            - �G���[�̃f�X�N�g�b�v�ʒm
��   ������ same-path.coffee               - �����̃p�X�����v���镔���̎擾
��   ������ to-relative-path.coffee        - �p�X�𑊑΃p�X��
������ gulpfile.coffee - gulp���C���X�N���v�g
������ package.json    - node�p�b�P�[�W
������ tsd.json        - TypeScript�^��`�t�@�C���p�b�P�[�W
```

�܂��A���L�̃f�B���N�g���ꗗ�͎�����������܂�

```
root
������ typings          - ������DefinitelyTyped�ɂ��^��`�t�@�C��(tsd update -s�Ő���)
������ src_typings      - src��ΏۂƂ������[�U�����^��`�t�@�C�� (gulp (build | watch)�Ő���)
������ test_src_typings - test_src��ΏۂƂ������[�U�����^��`�t�@�C�� (gulp (test | test:watch)�Ő���)
������ public           - src���ʕ�
������ test_public      - test_src���ʕ�
��������͈ꎞ�f�B���N�g��(�������Ă��ǂ�)
������ lib
������ lib_tmp
������ src_typings_tmp
������ test_lib
������ test_lib_tmp
������ test_src_typings_tmp

```

# <a name="alias"></a> �\�[�X�ւ�require�p��alias�A���[�U�O�����W���[�����ɂ���

�\�[�X���ɓƎ��^�O�ł���
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

�𖄂ߍ��ނ��Ƃɂ��A
gulpscripts/ambient-external-module.coffee
���\�[�X���̃^�O�����W���Abrowserify�Ƀ\�[�X��ǉ�����ۂ�require���\�b�h�ɂ��alias����`����܂�

```coffee
b.require('lib/path/to/hoge.js', expose: 'hoge')
```

�܂��ATypeScript�̏ꍇ��dts-bundle�ɂ��O�����W���[��������src_typings�f�B���N�g�����Ƀ��[�U�^��`�t�@�C�����쐬����邽�߁A

```ts
/// <reference path="root/src_typings/tsd.d.ts" />

import Hoge = require('hoge');
Hoge.foo();
```

�Ƃ��������������鎖���o���܂��B

# <a name="multi_source_map"></a> ���i�\�[�X�}�b�v�̉����ɂ���

AltJS����browserify�ɂ��bundle�t�@�C�������܂ł̗���́A�ȉ��̂悤�ɂȂ��Ă��܂��B

- 1.AltJS�̃g�����X�p�C��
	- hoge.ts -> tsc -> hoge.js & hoge.js.map
	- foo.coffee -> coffee -c -> foo.js & foo.js.map
- 2.browserify�ɂ��bundle
	- (hoge.js & hoge.js.map) & (foo.js & foo.js.map) -> browserify -> bundle.js & bundle.js.map
		
���ԃt�@�C���ł���hoge.js��foo.js�̂��ꂼ��̃\�[�X�}�b�v�t�@�C����AltJS�Ƃ̕R�Â��A
�������ł���bundle.js�̃\�[�X�}�b�v�t�@�C���͒��ԃt�@�C���Ƃ̕R�Â������ꂽ��Ԃł���A
bundle.js�̃\�[�X�}�b�v�t�@�C������AAltJS�ւƒ��ڕR�Â���K�v������܂��B

�R�Â����@�ł����A[mozilla/source-map](https://github.com/mozilla/source-map/)�ɂ��\�[�X�}�b�v���̑Ή������ʒu�����v���b�g���Ă݂�ƁA
���ԃt�@�C���̃\�[�X�}�b�v�t�@�C���ł���hoge.js.map��foo.js.map��generated�̈ʒu���ƁA
�������̃\�[�X�}�b�v�t�@�C���ł���bundle.js.map��original�̈ʒu��񂪑΂ɂȂ��Ă���Ɠǂݎ��܂��B

![�\�[�X�}�b�v�̃v���b�g�摜](https://github.com/wordijp/altjs-browserify-base-project/blob/master/multi_source_map_prot.png)

���̑΂ɂȂ��Ă���ʒu������ɁAAltJS��original�̈ʒu���ƁA��������bundle.js��generated�̈ʒu�������o����΁A���i�\�[�X�}�b�v�̖�肪�����o���鎖�ɂȂ�܂��B

���̖�����������X�N���v�ggulpscripts/merge-multi-sourcemap.coffee���쐬���Abrowserify���s��ɑ��点�邱�Ƃł��̖����������Ă��܂��B
- ���X�N���v�g���ł́A����ɍׂ����R�Â������Ă��܂��B
- **��browserify��uglify�ɂ�鈳�k��̃\�[�X�}�b�v�Ɏ����܂������A��̈ʒu�������ɂ���錋�ʂƂȂ��Ă��܂����ׁAuglify�ƕ��p�����ꍇ�͏�肭�����Ȃ��\��������܂��B**

- �Q�l)
	- [Source Map�������֘A���C�u�����̂܂Ƃ�](http://efcl.info/2014/0622/res3933/)
	- https://github.com/azu/multi-stage-sourcemap
		
# <a name="using_react_for_mocha"></a> mocha��React�Ή��ɂ���


## �t�@�C���\���ɂ���

�e�X�g�p��js�t�@�C���́A���L�̍\���ɂȂ��Ă��܂��B

```
�R���\�[���p
������ get-document.js                   - jsdom�ɂ�鉼�zDOM�擾
������ run-source-map-support.js         - source-map-support.js���s���̃\�[�X�}�b�v����

�u���E�U�p
������ get-document-bundle.js            - jquery�ɂ��HTML���DOM�擾
������ run-browser-source-map-support.js - browser-source-map-support.js���s���̃\�[�X�}�b�v����

����
������ test-bundle.js                    - test_src�̃\�[�X��bundle�t�@�C��
```

�R���\�[�����A�u���E�U���ō��ق̂���DOM�擾������ʃt�@�C���ɐ؂肾���A���ꂼ��̊��œǂݍ���ł��܂��B

Browserify��test-bundle.js��bundle���A

```
b.exclude('./get-document')
```

��exclude���A�u���E�U�p��get-document-bundle.js��bundle����

```
b.require('get-document-bundle.js', expose: './get-document')
```

��require�����`����test-bundle.js���猩����悤�ɂ��Ă��܂��B  
�R���\�[�����ł͓����ƂȂ�get-document.js�̂܂܂ɂ��āAnode.js����require�𗘗p�����◠�Z�I�ȕ��@�őΏ����Ă��܂��B

## run-(browser-)source-map-support.js�ɂ���

���i�\�[�X�}�b�v�𗘗p���Ă��邽�߁AsourceMapSupport.install()��retrieveSourceMap���\�b�h���ŁA�e�t�@�C���ɑΉ������\�[�X�}�b�v��Ԃ��K�v������܂��B

```
sourceMapSupport.install({
  retrieveSourceMap: function(source) {
    if (source === "test-bundle.js") {
	  return test-bundle.js.map�f�[�^
	}
	...
  }
})
```

���̃f�[�^�́Arun-(browser-)source-map-support.js�̐������Ƀ\�[�X�}�b�v�t�@�C����ǂݍ���Ŗ��ߍ��ގ��ɂ��Ώ����Ă��܂��B

# <a name="about_bundle_file"></a> bundle�t�@�C���̍\���ɂ���

bundle�t�@�C���́AReact���̋���module��bundle����common-bundle.js�ƁA�J������src�f�B���N�g����bundle����bundle.js�ɕ����Ă��܂��B

```
public
������ bundle.js        - src�f�B���N�g����bundle
������ common-module.js - ����module��bundle(React��)
```

�J������gulp watch���J�n���Asrc�f�B���N�g���̃R�[�f�B���O�������ۂ�bundle.js�����������r���h�̑ΏۂƂ��鎖�ō�bundle���Ԃ̒Z�k��}���Ă��܂��B
���ӓ_�Ƃ��Ă�bundle�t�@�C�����������鎖�ւ̔F���ƁAgulpfile��common-module.js�ɐ؂�o���ݒ�Y��������bundle.js����module���܂܂�Ă��܂�����A�؂�o�����܂܂ɂ���Ɩ��g�p�̋���module��common-bundle.js���Ɋ܂܂�Ă��܂����ł��B
���ׁ̈Acommon-module.js�ւƐ؂�o�����́A�g�p�����Ԃ��s�ςł���(React��Web�T�C�g�����ꍇ��React��K���g���ׁAReact��؂�o���̂͑Ó�)module��I�񂾕����A�`�[�����ł��ǂ��؂�o���ׂ����̍��������Ȃ��ς݂܂��B

```coffee:gulpfile.coffee
# react���W���[�����Acommon-bundle.js��
gulp.task 'browserify-requireonly', () ->
  browserifyTask.browserifyBundleStreamRequireOnly(['react'], 'public', {bundle_name: 'common-bundle.js'})

# react���W���[�����Abundle.js�֊܂߂Ȃ�
createBrowserifyStream = (watching) ->
  browserifyTask.browserifyBundleStream('lib', 'public', {watching: watching, excludes: ['react'], bundle_name: 'bundle.js'})

gulp.task 'browserify', () -> createBrowserifyStream(false)
```

# TypeScript�̒�`�t�@�C���ɂ���

��`�t�@�C���́ADefinitelyTyped�ɂ����J����Ă��郂�W���[���p�Esrc�f�B���N�g���p�Etest_src�f�B���N�g���p��3��ނ�����A
src�p�Atest_src�p��gulp�Ŏ�����������ATypeScript��ҏW�����ۂɂ������X�V����܂��B

������DefinitelyTyped�Ɠ��l�Ƀ��[�g�p�̒�`�t�@�C��(tsd.d.ts)��p�ӂ��Ă���ׁA���ꂼ��̒�`�t�@�C�����Q�Ƃ��邾���ł悢�ł��B

- DefinitelyTyped�p�̒�`�t�@�C��
	- typings/tsd.d.ts
		
- src�f�B���N�g���p�̒�`�t�@�C��
	- src_typings/tsd.d.ts

- test_src�f�B���N�g���p�̒�`�t�@�C��
	- test_src_typings/tsd.d.ts


```ts
/// src�f�B���N�g���̏ꍇ
/// <reference path="../../typings/tsd.d.ts" />
/// <reference path="../../src_typings/tsd.d.ts" />
```

```ts
/// test_src�f�B���N�g���̏ꍇ
/// <reference path="../../typings/tsd.d.ts" />
/// <reference path="../../test_src_typings/tsd.d.ts" />
```

# Licence

MIT
