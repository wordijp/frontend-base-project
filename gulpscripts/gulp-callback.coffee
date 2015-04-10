# streamの流れの中でコールバックを呼べるようにする

through = require 'through2'

module.exports = (cb) ->
  transform = (file, encoding, callback) ->
    this.push(file)
    callback()

  flush = (callback) ->
    cb()
    callback()

  through.obj(transform, flush)
