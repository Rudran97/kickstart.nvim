local M = {}

function M.root() return require('custom.workspace').get_root() or vim.fn.getcwd() end

local function run_in_root(cmd)
  local root = M.root()

  if root then vim.cmd('cd ' .. vim.fn.fnameescape(root)) end

  vim.cmd(cmd)
end

function M.open() run_in_root 'LazyGit' end
function M.diff() run_in_root 'DiffviewOpen' end
function M.close() run_in_root 'DiffviewClose' end
function M.file_history() run_in_root 'DiffviewFileHistory %' end
function M.repo_history() run_in_root 'DiffviewFileHistory' end

return M
