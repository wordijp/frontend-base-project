_          = require 'lodash'
Enumerable = require 'linq'

aem = require '../ambient-external-module'

# NOTE : TypeScript関係はts-taskへ

prev_aliases = {}
checkRenameModule = (root, changed_cb) ->
  aliases = Enumerable.from(aem.collect {root: root, include_ext: ['.ts', '.coffee', '.cjsx'], exclude_ext: ['.d.ts']})
    .where(aem.isAlias)
    .select((x) -> x.value)
    .toArray()

  if (prev_aliases[root]? && prev_aliases[root].length > 0)
    equal = true
    equal = equal && prev_aliases[root].length is aliases.length
    equal = equal && _.difference(aliases, prev_aliases[root]).length is 0
    equal = equal && _.difference(prev_aliases[root], aliases).length is 0
    if (!equal)
      changed_cb()

  prev_aliases[root] = aliases

# exports ---

module.exports =
  checkRenameModule: checkRenameModule
