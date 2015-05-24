/// <reference path="../../typings/tsd.d.ts" />

var getDocument = require('./get-document');
global['document'] = getDocument();

global['window'] = document.defaultView;
global['navigator'] = window.navigator;

import chai = require('chai');
var assert = chai.assert;

import React = require('react/addons');
var TestUtils = React.addons.TestUtils;

import sinon = require('sinon');

describe('add test for TypeScript', () => {
  it('replace add to mul (using sinon.stub)', () => {
    var Add = require('../../lib/scripts/add');

    // addの処理を乗算に差し替える
    var mul = (a, b) => {
      return a * b;
    };
    var stub = sinon.stub(Add.prototype.__reactAutoBindMap, "add", mul);

    // オンメモリ上にレンダリング
    var tmpl = require('./add-template');
    var doc = TestUtils.renderIntoDocument(tmpl({Add: Add, a: 10, b: 20}));

    // class="answer"の付いたタグを取得
    var answer = TestUtils.scryRenderedDOMComponentsWithClass(doc, 'answer')[0];

    // 値の比較
    assert.equal(answer.props.children, 200);
  });
});
