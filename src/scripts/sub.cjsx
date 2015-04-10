React = require('react')

Sub = React.createClass(
  sub: (a, b) ->
    a - b

  render: () ->
    a = this.props.a
    b = this.props.b
    ans = this.sub(a, b)

    <div>
      {a} - {b} = <span className="answer">{ans}</span>
    </div>
)
module.exports = Sub
