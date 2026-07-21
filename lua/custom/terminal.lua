local M = {}

function M.toggle() require('floaterm').toggle() end
function M.new() require('floaterm.api').new_term() end

function M.delete()
  local state = require 'floaterm.state'
  require('floaterm.api').delete_term(state.buf)
end

return M
