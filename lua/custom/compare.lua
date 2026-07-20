local M = {}

local workspace = require 'custom.workspace'

local ignored = {
  ['.git'] = true,

  -- Build directories
  ['build'] = true,
  ['bin'] = true,
  ['obj'] = true,
  ['out'] = true,
  ['dist'] = true,

  -- Package managers
  ['node_modules'] = true,
  ['.venv'] = true,
  ['venv'] = true,
  ['__pycache__'] = true,

  -- IDE
  ['.idea'] = true,
  ['.vscode'] = true,

  -- Quartus
  ['db'] = true,
  ['incremental_db'] = true,
  ['greybox_tmp'] = true,
  ['simulation'] = true,
  ['output_files'] = true,

  -- Vivado
  ['.Xil'] = true,
  ['.cache'] = true,
  ['.runs'] = true,
  ['.gen'] = true,
  ['.hw'] = true,
  ['.ip_user_files'] = true,
  ['sim'] = true,
}

local uv = vim.uv

----------------------------------------------------------------------
---------------------- Common helper functions -----------------------
----------------------------------------------------------------------

local function workspace_entries(current_file)
  local root = workspace.get_root()
  local entries = {}

  local function recurse(dir)
    local fs = uv.fs_scandir(dir)
    if not fs then return end

    while true do
      local name, typ = uv.fs_scandir_next(fs)
      if not name then break end
      local path = dir .. '/' .. name

      if typ == 'directory' then
        if not ignored[name] then recurse(path) end
      elseif typ == 'file' then
        local relative = vim.fs.relpath(root, path) or name

        table.insert(entries, {
          value = path,
          ordinal = relative,
          name = name,
          relative = relative,
          current = vim.fn.resolve(path) == vim.fn.resolve(current_file),
        })
      end
    end
  end

  recurse(root)
  table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)
  table.insert(entries, {
    value = '__browse__',
    ordinal = 'compare_zzzz',
    name = 'Compare with file outside workspace...',
    relative = 'Press <Tab> for path completion',
    current = false,
  })

  return entries
end

----------------------------------------------------------------------

local function telescope_picker(title, entries, callback)
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = title,
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry.value,
            display = string.format('%s%-30s %s', entry.current and '● ' or '  ', entry.name, entry.relative),
            ordinal = entry.ordinal,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          callback(selection)
        end)
        return true
      end,
    })
    :find()
end

----------------------------------------------------------------------

local function compare_files(left, right)
  vim.cmd 'tabnew'
  vim.cmd('edit ' .. left)
  vim.cmd 'diffthis'
  vim.wo.foldmethod = 'manual'
  vim.cmd 'normal! zR' -- Open all folds
  vim.wo.scrollbind = true
  vim.wo.cursorbind = true

  vim.cmd 'vsplit'
  vim.cmd('edit ' .. right)
  vim.cmd 'diffthis'
  vim.wo.foldmethod = 'manual'
  vim.cmd 'normal! zR' -- Open all folds
  vim.wo.scrollbind = true
  vim.wo.cursorbind = true

  --- jump to the first difference ---
  vim.cmd 'normal! gg'
  pcall(function() vim.cmd 'normal! ]c' end)

  vim.cmd 'wincmd h'

  vim.schedule(
    function()
      vim.keymap.set('n', 'q', '<cmd>tabclose<CR>', {
        buffer = true,
        silent = true,
        desc = 'Close Compare',
      })
    end
  )
end

local function compare_current_with(path)
  local current = vim.api.nvim_buf_get_name(0)

  if current == '' then
    vim.notify('Current buffer has no associated file.', vim.log.levels.WARN)
    return
  end

  current = vim.fn.resolve(current)
  path = vim.fn.resolve(path)

  if current == path then
    vim.notify('Selected file is already the current buffer.', vim.log.levels.INFO)
    return
  end

  compare_files(current, path)
end

----------------------------------------------------------------------

local function browse_file()
  vim.ui.input({

    prompt = 'Compare with: ',

    default = workspace.get_root() .. '/',

    completion = 'file',
  }, function(path)
    if not path or path == '' then return end

    compare_current_with(path)
  end)
end

function M.compare_current()
  local current = vim.api.nvim_buf_get_name(0)

  if current == '' then
    vim.notify('Current buffer has no associated file.', vim.log.levels.WARN)

    return
  end

  local entries = workspace_entries(current)

  telescope_picker('Compare Current File', entries, function(selection)
    if selection == '__browse__' then
      browse_file()
    else
      compare_current_with(selection)
    end
  end)
end

----------------------------------------------------------------------
----------------------------- Public API -----------------------------
----------------------------------------------------------------------

vim.api.nvim_create_user_command('CompareCurrentFile', function() require('custom.compare').compare_current() end, {})

return M
