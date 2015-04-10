getDocument = require('./get-document')
global.document = getDocument()

global.window = document.defaultView
global.navigator = window.navigator

chai = require('chai')
assert = chai.assert

React = require('react/addons')
TestUtils = React.addons.TestUtils

sinon = require('sinon')

describe 'sub test for coffee-react(jsx記法対応のCoffeeScript)', () ->
  it 'replace sub to div(using sinon.stub)', () ->
    # NOTE : やってる事はTypeScript(add-test)側と同じ
    Sub = require('../../lib/scripts/sub')

    # subの処理を除算に差し替える
    div = (a, b) -> a / b
    sinon.stub(Sub.prototype.__reactAutoBindMap, "sub", div)

    # オンメモリ上にレンダリング
    doc = TestUtils.renderIntoDocument(<Sub a=30 b=6 />)

    # class="answer"の付いたタグを取得
    answer = TestUtils.scryRenderedDOMComponentsWithClass(doc, 'answer')[0]

    # 値の比較
    assert.equal(answer.props.children, 5)
