local M = {}

function M.root() return require('custom.workspace').get_root() end

function M.open()
  local root = M.root()

  if root then vim.cmd('cd ' .. vim.fn.fnameescape(root)) end

  vim.cmd 'LazyGit'
end

------------------------------------------------------------

return M
