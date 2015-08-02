###
<ambient-external-module alias="{filename}" />
###

React = require('react')

Add = React.createClass(
  add: (a, b) ->
    a + b

  render: () ->
    a = this.props.a
    b = this.props.b
    ans = this.add(a, b)

    <div>
      {a} + {b} = <span className="answer">{ans}</span>
    </div>
)
module.exports = Add
