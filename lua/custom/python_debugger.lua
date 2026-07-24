local M = {}

local dap = require 'dap'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local python_override = nil

local function project_root()
  --- prefer an attached LSP workspace ---
  for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
    if client.config.root_dir then return client.config.root_dir end
  end

  return vim.fn.getcwd()
end

--- interpreter selection ---
local function detect_automatic_python()
  --- activated virtualenv ---
  local venv = vim.env.VIRTUAL_ENV
  if venv then
    local python = venv .. '/bin/python'
    if vim.fn.executable(python) == 1 then return python end
  end

  --- activated conda environment ---
  local conda = vim.env.CONDA_PREFIX
  if conda then
    local python = conda .. '/bin/python'
    if vim.fn.executable(python) == 1 then return python end
  end

  -- search current project ---
  local root = project_root()

  local candidates = {
    root .. '/.venv/bin/python',
    root .. '/venv/bin/python',
    root .. '/.env/bin/python',
    root .. '/env/bin/python',
  }

  for _, python in ipairs(candidates) do
    if vim.fn.executable(python) == 1 then return python end
  end

  -- 4. Fall back to system Python
  return vim.fn.exepath 'python3'
end

local function discover_interpreters()
  local cwd = vim.fn.getcwd()
  local interpreters = {
    {
      name = 'Automatic (recommended)',
      path = nil,
      description = detect_automatic_python(),
    },
  }
  local candidates = {
    {
      name = 'Project .venv',
      path = cwd .. '/.venv/bin/python',
    },
    {
      name = 'Project venv',
      path = cwd .. '/venv/bin/python',
    },
    {
      name = 'Project .env',
      path = cwd .. '/.env/bin/python',
    },
    {
      name = 'Project env',
      path = cwd .. '/env/bin/python',
    },
    {
      name = 'System Python',
      path = vim.fn.exepath 'python3',
    },
  }

  for _, candidate in ipairs(candidates) do
    if candidate.path ~= '' and vim.fn.executable(candidate.path) == 1 then table.insert(interpreters, candidate) end
  end

  table.insert(interpreters, {
    name = 'Browse...',
    browse = true,
  })

  return interpreters
end

function M.select_interpreter()
  pickers
    .new({}, {
      prompt_title = 'Python Interpreters',

      finder = finders.new_table {
        results = discover_interpreters(),

        entry_maker = function(item)
          local marker = ' '

          -- automatic mode
          if item.name == 'Automatic (recommended)' and python_override == nil then
            marker = '●'
          -- explicit interpreter
          elseif item.path ~= nil and item.path == python_override then
            marker = '●'
          end

          local path = item.description or item.path or ''
          return {
            value = item,
            display = string.format('%s %-22s %s', marker, item.name, path),
            ordinal = item.name,
          }
        end,
      },

      sorter = conf.generic_sorter {},

      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry().value

          actions.close(prompt_bufnr)

          if selection.browse then
            python_override = vim.fn.input('Python interpreter: ', detect_automatic_python(), 'file')
            return
          end

          python_override = selection.path
        end)

        return true
      end,
    })
    :find()
end

function M.resolve_python()
  if python_override then return python_override end
  return nil
end

function M.configuration() return dap.configurations.python[1] end

function M.current_interpreter()
  if python_override then return python_override end
  local detected = detect_automatic_python()
  if detected ~= '' then return 'Automatic - ' .. vim.fn.fnamemodify(detected, ':~') end
  return 'Automatic'
end

return M
