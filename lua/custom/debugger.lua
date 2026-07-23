local M = {}

local dap = require 'dap'
local dapui = require 'dapui'

local last_program = nil

function M.continue() dap.continue() end
function M.step_into() dap.step_into() end
function M.step_over() dap.step_over() end
function M.step_out() dap.step_out() end
function M.toggle_breakpoint() dap.toggle_breakpoint() end
function M.conditional_breakpoint() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end
function M.toggle_ui() dapui.toggle() end
function M.select_program() last_program = vim.fn.input('Executable: ', vim.fn.getcwd() .. '/', 'file') end
function M.program()
  if last_program == nil then M.select_program() end
  return last_program
end
function M.terminate()
  if dap.session() then dap.terminate() end
end

return M
