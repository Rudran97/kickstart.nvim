local M = {}

local workspace = require 'custom.workspace'

local ignored = {
  ['.git'] = true,
  ['.github'] = true,

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
    ordinal = 'browse_zzzz',
    name = 'Compare with file outside workspace...',
    relative = 'Press <Tab> for path completion',
    current = false,
  })

  return entries
end

local function workspace_directories(current_dir)
  local root = workspace.get_root()
  local entries = {}

  local function recurse(dir)
    local fs = uv.fs_scandir(dir)
    if not fs then return end

    while true do
      local name, typ = uv.fs_scandir_next(fs)
      if not name then break end

      if typ == 'directory' and not ignored[name] then
        local path = dir .. '/' .. name
        local relative = vim.fs.relpath(root, path) or name

        table.insert(entries, {
          value = path,
          ordinal = relative,
          name = name,
          relative = relative,
          current = vim.fn.resolve(path) == vim.fn.resolve(current_dir),
        })

        recurse(path)
      end
    end
  end

  recurse(root)

  table.sort(entries, function(a, b) return a.ordinal < b.ordinal end)

  table.insert(entries, {
    value = '__browse__',
    ordinal = 'browse_zzzz',
    name = 'Compare with directory outside workspace...',
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
--------------------------- Compare Files ----------------------------
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

function M.compare_file()
  local current = vim.api.nvim_buf_get_name(0)

  if current == '' then
    vim.notify('Current buffer has no associated file.', vim.log.levels.WARN)

    return
  end

  local entries = workspace_entries(current)

  telescope_picker('Select a File to Compare with the Current File', entries, function(selection)
    if selection == '__browse__' then
      browse_file()
    else
      compare_current_with(selection)
    end
  end)
end

----------------------------------------------------------------------
------------------------- Compare Directory --------------------------
----------------------------------------------------------------------

local function directory_files(root)
  local files = {}

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
        local relative = vim.fs.relpath(root, path)

        if relative then files[relative] = path end
      end
    end
  end

  recurse(root)

  return files
end

local function compare_directories(left_root, right_root)
  left_root = vim.fn.resolve(left_root)
  right_root = vim.fn.resolve(right_root)

  if left_root == right_root then
    vim.notify('Selected directory is already the current directory.', vim.log.levels.INFO)
    return
  end

  local left_files = directory_files(left_root)
  local right_files = directory_files(right_root)
  local entries = {}

  --- find deleted and modified files ---
  for relative, left_path in pairs(left_files) do
    local right_path = right_files[relative]

    if not right_path then
      table.insert(entries, {
        status = 'D',
        relative = relative,
        left = left_path,
        right = nil,
      })
    else
      local left_data = table.concat(vim.fn.readfile(left_path, 'b'), '\n')
      local right_data = table.concat(vim.fn.readfile(right_path, 'b'), '\n')

      if left_data ~= right_data then
        table.insert(entries, {
          status = 'M',
          relative = relative,
          left = left_path,
          right = right_path,
        })
      end
    end
  end

  --- find added files ---
  for relative, right_path in pairs(right_files) do
    if not left_files[relative] then
      table.insert(entries, {
        status = 'A',
        relative = relative,
        left = nil,
        right = right_path,
      })
    end
  end

  table.sort(entries, function(a, b) return a.relative < b.relative end)

  if #entries == 0 then
    vim.notify('Directories are identical.', vim.log.levels.INFO)
    return
  end

  vim.cmd 'tabnew'

  --- changed-files panel ---
  local list_buf = vim.api.nvim_get_current_buf()
  local list_win = vim.api.nvim_get_current_win()

  vim.bo[list_buf].buftype = 'nofile'
  vim.bo[list_buf].bufhidden = 'wipe'
  vim.bo[list_buf].swapfile = false

  local lines = {}

  for _, entry in ipairs(entries) do
    table.insert(lines, string.format('%s  %s', entry.status, entry.relative))
  end

  vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, lines)
  vim.bo[list_buf].modifiable = false

  --- left/current version ---
  vim.cmd 'vsplit'
  local left_win = vim.api.nvim_get_current_win()

  --- right/selected version ---
  vim.cmd 'vsplit'
  local right_win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(list_win, 35)

  local function set_close_key(win)
    local buf = vim.api.nvim_win_get_buf(win)

    vim.keymap.set('n', 'q', '<cmd>tabclose<CR>', {
      buffer = buf,
      silent = true,
      desc = 'Close Compare',
    })
  end

  local function open_selected()
    local line = vim.api.nvim_win_get_cursor(list_win)[1]
    local entry = entries[line]

    if not entry then return end

    --- current/left version ---
    vim.api.nvim_win_call(left_win, function()
      vim.cmd 'diffoff'

      if entry.left then
        vim.cmd('edit ' .. vim.fn.fnameescape(entry.left))
      else
        vim.cmd 'enew'
        vim.bo.buftype = 'nofile'
        vim.bo.bufhidden = 'wipe'
        vim.bo.swapfile = false
      end

      vim.cmd 'diffthis'
      vim.wo.foldmethod = 'manual'
      vim.cmd 'normal! zR'

      set_close_key(left_win)
    end)

    --- selected/right version ---
    vim.api.nvim_win_call(right_win, function()
      vim.cmd 'diffoff'

      if entry.right then
        vim.cmd('edit ' .. vim.fn.fnameescape(entry.right))
      else
        vim.cmd 'enew'
        vim.bo.buftype = 'nofile'
        vim.bo.bufhidden = 'wipe'
        vim.bo.swapfile = false
      end

      vim.cmd 'diffthis'
      vim.wo.foldmethod = 'manual'
      vim.cmd 'normal! zR'

      set_close_key(right_win)
    end)

    vim.api.nvim_set_current_win(list_win)
  end

  vim.keymap.set('n', '<CR>', open_selected, {
    buffer = list_buf,
    silent = true,
    desc = 'Open Directory Diff',
  })

  set_close_key(list_win)

  --- show first difference automatically ---
  vim.api.nvim_set_current_win(list_win)
  vim.api.nvim_win_set_cursor(list_win, { 1, 0 })
  open_selected()
end

function M.compare_directory()
  local current_file = vim.api.nvim_buf_get_name(0)

  if current_file == '' then
    vim.notify('Current buffer has no associated file.', vim.log.levels.WARN)
    return
  end

  local current_dir = vim.fn.resolve(vim.fn.fnamemodify(current_file, ':p:h'))
  local entries = workspace_directories(current_dir)

  telescope_picker('Select a Directory to Compare', entries, function(selection)
    if selection == '__browse__' then
      vim.ui.input({
        prompt = 'Compare with directory: ',
        default = workspace.get_root() .. '/',
        completion = 'dir',
      }, function(path)
        if not path or path == '' then return end

        if vim.fn.isdirectory(path) ~= 1 then
          vim.notify('Selected path is not a directory.', vim.log.levels.WARN)
          return
        end

        compare_directories(current_dir, path)
      end)

      return
    end

    compare_directories(current_dir, selection)
  end)
end

----------------------------------------------------------------------
----------------------------- Public API -----------------------------
----------------------------------------------------------------------

vim.api.nvim_create_user_command('CompareCurrentFile', function() require('custom.compare').compare_file() end, {})
vim.api.nvim_create_user_command('CompareCurrentDirectory', function() require('custom.compare').compare_directory() end, {})

return M
