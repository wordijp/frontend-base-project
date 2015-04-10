# ���isourcemap�̍������s��
# browserify�ő��isourcemap���g����̂�ړI�Ƃ��Ă���
#
# �Q�l) http://efcl.info/2014/0622/res3933/
#       https://github.com/azu/multi-stage-sourcemap

sourceMap = require "source-map"
Generator = sourceMap.SourceMapGenerator
Consumer  = sourceMap.SourceMapConsumer

_ = require 'lodash'

# �g�ݍ��݂�join�͒x���̂ŁA���̕ς��
strJoin = (strs, delim) ->
  str = ""
  for x, i in strs
    if (i > 0)
      str += delim
    str += x
  str

# path�̏璷�ȓo��~��𖳂���
# usage) path   : src/sub1/../sub2/a.ts
#        return : src/sub2/a.ts
resolvePath = (path) ->
  new_path = []
  for x in path.split('/')
    if (x is '..')
      if (new_path.length > 0 && new_path[new_path.length-1] isnt '..')
        new_path.pop()
      else
        new_path.push(x)
    else if (x is '.')
      # no-op
    else
      new_path.push(x)

  strJoin(new_path, '/')

# ������path��A������
joinPaths = () ->
  paths = arguments

  f = (a, b) ->
    if (a.length > 0 && b.length > 0)
      return a + '/' + b
    if (a.length > 0)
      return a
    b

  path = ""
  for x in paths
    path = f(path, x)
    
  path

# original�ʒu��a == b��
equalOriginal = (a, b) ->
  a.originalLine == b.originalLine && a.originalColumn == b.originalColumn
  
# original�ʒu��a > b��
greaterThanOriginal = (a, b) ->
  a.originalLine > b.originalLine ||
    (a.originalLine == b.originalLine && a.originalColumn > b.originalColumn)

# �����߂��Ă���ʒu��񓙂̕s�v��mapping����菜��
filteredUseMapping = (consumer) ->
  uses = []
  for source in consumer.sources
    
    is_first = true
    prev = undefined
    consumer.eachMapping((x) ->
      if (source != x.source)
        return

      if (!prev?)
        prev = x
        return

      # ����͎��̈ʒu���̈�O
      if (is_first)
        if (equalOriginal(x, prev))
          prev = x
          return

        uses.push(prev)
        is_first = false
        
      # ����ȍ~�͍ŏ��̈ʒu���
      if (greaterThanOriginal(x, prev))
        uses.push(x)
        prev = x
    )

  uses
 
# firsts��second��mapping����������
mergedGenerators = (firsts, firstUses, firstMapRoots, second, __, secondMapRoot) ->
  result = new Generator(
    file: second.file
    sourceRoot: second.sourceRoot
  )
  
  if (firsts.length != firstUses.length ||
      firsts.length != firstMapRoots.length)
    throw "length is illegal"
  
  firstFiles = []
  for i in [0...firsts.length]
    x = joinPaths(firstMapRoots[i], firsts[i].file)
    x = resolvePath(x)
    firstFiles.push(x)
  
  re = new RegExp('^(' + second.sourceRoot + '/)?')

  # NOTE : eachMapping��source�ɂ́A������SourceMapGenerator��sourceRoot���t�^����Ă���

  second.eachMapping (x) ->
    secondSource = joinPaths(secondMapRoot, x.source)
    secondSource = resolvePath(secondSource)

    firstIndex = _.findIndex(firstFiles, (x) -> x == secondSource)
    if (firstIndex < 0)
      # �����Ɩ��֌W�Ȃ炻�̂܂ܒǉ�
      result.addMapping(
        source: x.source.replace(re, '')
        name: x.name
        generated:
          line: x.generatedLine
          column: x.generatedColumn
        original:
          line: x.originalLine
          column: x.originalColumn
      )
      return
    
    # �R�Â���first������
    relation_first = undefined
    for y in firstUses[firstIndex]
      if (x.originalLine == y.generatedLine)
        relation_first = y
        break

    # ��������mapping��ǉ�����
    if (relation_first?)
      firstSource = joinPaths(firstMapRoots[firstIndex], relation_first.source)
      firstSource = resolvePath(firstSource)

      result.addMapping(
        source: firstSource
        name: relation_first.name
        generated:
          line: x.generatedLine
          column: x.generatedColumn
        original:
          line: relation_first.originalLine
          column: relation_first.originalColumn
      )

  result
  
# ���sourcemap���������ĕԂ�
# firstObj   : ��i�K�ڃg�����X�p�C�����sourcemap object
# secondObj  : ��i�K��(�ŏI)�g�����X�p�C�����sourcemap object
# NOTE : sourcemap object : { value: map�t�@�C���̕�����, maproot: map�t�@�C���̃��[�g�p�X }
merge = (firstObj, secondObj) -> merges([firstObj], secondObj)

module.exports.merge = merge


# ������sourcemap���������ĕԂ�
# firstObjs  : ��i�K�ڃg�����X�p�C����̕�����sourcemap object
# secondObj  : ��i�K��(�ŏI)�g�����X�p�C�����sourcemap object
merges = (firstObjs, secondObj) ->
  firsts = firstObjs.map((x) -> new Consumer(x.value))
  second = new Consumer(secondObj.value)
  
  firstUses = firsts.map((x) -> filteredUseMapping(x))
  #secondUses = filteredUseMapping(second)

  result = mergedGenerators(
    firsts, firstUses, firstObjs.map((x) -> x.maproot),
    second, undefined, secondObj.maproot
  )

  result.toString()

module.exports.merges = merges
