local M = {}

local workspace_root = nil
local launch_directory = vim.fn.getcwd()

---------------------------------------------------------------

function M.set_root(root) workspace_root = root end

---------------------------------------------------------------

function M.clear() workspace_root = nil end

---------------------------------------------------------------

function M.get_root() return workspace_root or launch_directory end

---------------------------------------------------------------

function M.get_launch_directory() return launch_directory end

return M
