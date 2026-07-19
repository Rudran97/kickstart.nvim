local M = {}

----------------------------------------------------------------------
------------------------------ Backend -------------------------------
----------------------------------------------------------------------

local function backend_close() vim.cmd 'Neotree close' end
local function backend_sidebar(root) vim.cmd(string.format('Neotree filesystem reveal left dir=%s', vim.fn.fnameescape(root))) end
local function backend_float(root) vim.cmd(string.format('Neotree filesystem reveal float dir=%s', vim.fn.fnameescape(root))) end

----------------------------------------------------------------------
----------------------------- Public API -----------------------------
----------------------------------------------------------------------

function M.root()
  local workspace = require 'custom.workspace'
  return workspace.get_root()
end

----------------------------------------------------------------------

--- function to check if either the sidebar or the floating explorer is open ---
function M.is_open()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)

      if vim.bo[buf].filetype == 'neo-tree' then return true end
    end
  end

  return false
end

----------------------------------------------------------------------

function M.close()
  if not M.is_open() then return end

  backend_close()
end

----------------------------------------------------------------------

function M.sidebar()
  if M.is_open() then
    M.close()
    return
  end

  backend_sidebar(M.root())
end

----------------------------------------------------------------------

function M.focus()
  local current_tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(current_tab)) do
    local buf = vim.api.nvim_win_get_buf(win)

    if vim.bo[buf].filetype == 'neo-tree' then
      vim.api.nvim_set_current_win(win)
      return true
    end
  end

  return false
end

----------------------------------------------------------------------

function M.float()
  if M.is_open() then
    M.close()
    return
  end

  backend_float(M.root())
end

--- lifecycle events ---
function M.workspace_changing(callback)
  M.close()

  -- Give Neovim one event loop to process the close.
  vim.schedule(function()
    if callback then callback() end
  end)
end

return M
