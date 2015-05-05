esprima = require('esprima')
traverse = require('ordered-ast-traverse')

# require構文か
predicateRequire = (node) ->
  if (node.type != 'CallExpression' || node.callee.type != 'Identifier' || node.callee.name != 'require')
    return false
  true

# dataをパースし、predicateと一致する部分をcbへと渡す
# @param data      : パース対象データ
# @param predicate : とある構文とのチェッカー
# @param cb        : 一致した部分文字列を受け取るコールバック
astParser = (data, predicate, cb) ->
  traverse(esprima.parse(data, {range: true}), {pre: (node, parent, prop, idx) ->
    if (predicate(node))
      pth = node.arguments[0].value
      if (pth)
        cb(pth)
  })

astRequireParser = (data, cb) -> astParser(data, predicateRequire, cb)

module.exports =
  astRequireParser: astRequireParser
