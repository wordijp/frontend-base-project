/// <reference path="../../typings/tsd.d.ts" />

import React = require('react');
var Add = require('add');   // 独自タグを設定している(add.cjsx参照)
//var Add = require('./add'); // 従来の方法
var Sub = require('./sub');

var App = React.createClass({

  getInitialState: function() {
    return {
      tmpl: require('./app-template')
    };
  },

  render: function() {
    return this.state.tmpl({
      Add: Add, a: 1, b: 2,
      Sub: Sub, c: 7, d: 3
    });
  }
});

React.render(
  React.createElement(App, null),
  document.getElementById('main')
)
