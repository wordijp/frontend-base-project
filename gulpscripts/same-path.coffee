_ = require 'lodash'

# paths内の一致する部分を返す
# usage)
#   # return "src/scripts"
#   samePath([
#     "src/scripts/a.txt"
#     "src/scripts/b.txt"
#     "src/scripts/components/c.txt"
#   ])
module.exports = (files) ->
  if (files.length == 0)
    return ""
  
  # ファイル名を取り除く
  paths = files.map((x) -> x.split("/")[0...-1])

  hit = 0
  min_path = _.min(paths.map((x) -> x.length))
  for i in [0...min_path]
    word = paths[0][i]
    # 不一致があったら抜ける
    wrong_index = _.findIndex(paths, (x) -> x[i] != word)
    if (wrong_index >= 0)
      break
    
    hit = i

  paths[0][0..hit].join('/')
