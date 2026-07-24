local M = {}

local dap = require 'dap'
local dapui = require 'dapui'
local python = require 'custom.python_debugger'

local last_executable = nil
local last_target = nil

M.targets = {}

--- locate the debugger executables (gdb, lldb etc.) ---
local function exepath(program)
  local path = vim.fn.exepath(program)
  if path == '' then return 'Not found in PATH' end
  return path
end

M.targets = {
  {
    name = 'Native (LLDB)',
    path = exepath 'codelldb',
    configuration = {
      name = 'Native (LLDB)',
      type = 'codelldb',
      request = 'launch',
      program = function() return M.executable() end,
      cwd = '${workspaceFolder}',
      stopOnEntry = false,
      args = {},
    },
    select_program = function() M.select_executable() end,
  },
  {
    name = 'Native (GDB)',
    path = exepath 'gdb',
    configuration = {
      name = 'Native (GDB)',
      type = 'gdb',
      request = 'launch',
      program = function() return M.executable() end,
      cwd = '${workspaceFolder}',
      stopAtBeginningOfMainSubprogram = false,
      args = {},
    },
    select_program = function() M.select_executable() end,
  },
  {
    name = 'Python',
    path = python.current_interpreter,
    configuration = function() return python.configuration() end,
    select_program = function() python.select_interpreter() end,
  },
}

---------------------------------------------------------------

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local function select_target(callback)
  pickers
    .new({}, {
      prompt_title = 'Debug Targets',
      finder = finders.new_table {
        results = M.targets,
        entry_maker = function(target)
          local marker = ' '
          if last_target == target then marker = '●' end
          local path = target.path
          if type(path) == 'function' then path = path() end

          return {
            value = target,
            display = string.format('%s %-18s %s', marker, target.name, path),
            ordinal = target.name,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          callback(selection.value)
        end)
        return true
      end,
    })
    :find()
end

---------------------------------------------------------------

local function default_python_interpreter()
  local cwd = vim.fn.getcwd()
  local candidates = {
    cwd .. '/.venv/bin/python',
    cwd .. '/venv/bin/python',
  }
  for _, path in ipairs(candidates) do
    if vim.fn.executable(path) == 1 then return path end
  end
  return vim.fn.exepath 'python3'
end

---------------------------------------------------------------

function M.continue()
  -- if we're already debugging, just continue execution.
  if dap.session() then
    dap.continue()
    return
  end

  -- otherwise start a new session.
  if last_target then
    local cfg = last_target.configuration
    if type(cfg) == 'function' then cfg = cfg() end
    dap.run(cfg)
    return
  end

  select_target(function(target)
    last_target = target
    local cfg = target.configuration
    if type(cfg) == 'function' then cfg = cfg() end
    dap.run(cfg)
  end)
end

function M.step_into() dap.step_into() end
function M.step_over() dap.step_over() end
function M.step_out() dap.step_out() end
function M.toggle_breakpoint() dap.toggle_breakpoint() end
function M.conditional_breakpoint() dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ') end
function M.toggle_ui() dapui.toggle() end
function M.select_executable() last_executable = vim.fn.input('Executable: ', vim.fn.getcwd() .. '/', 'file') end

function M.executable()
  if last_executable == nil then M.select_executable() end
  return last_executable
end

function M.terminate()
  if dap.session() then dap.terminate() end
end

function M.select_target()
  select_target(function(target) last_target = target end)
end

function M.select_program()
  if not last_target then
    vim.notify('No debugger selected.', vim.log.levels.WARN)
    return
  end
  last_target.select_program()
end

return M
