local M = {}

local workspace = require 'custom.workspace'
local uv = vim.uv

local repositories = {}
local current_repo = nil

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
  ['.env'] = true,
  ['__pycache__'] = true,

  -- IDE / editor
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

--- get workspace root ---
function M.workspace_root() return workspace.get_root() or vim.fn.getcwd() end

function M.root()
  if current_repo then return current_repo.path end
  return M.workspace_root()
end

--- scan for git repositories ---
local function scan(root)
  local results = {}

  local function recurse(dir)
    local git = dir .. '/.git'

    if uv.fs_stat(git) then
      if dir ~= root then
        table.insert(results, {
          name = vim.fs.basename(dir),
          path = dir,
          kind = 'repository',
          relative_path = vim.fs.relpath(root, dir) or '.',
        })
      end
    end

    local fs = uv.fs_scandir(dir)
    if not fs then return end

    while true do
      local name, typ = uv.fs_scandir_next(fs)

      if not name then break end

      if typ == 'directory' and not ignored[name] then recurse(dir .. '/' .. name) end
    end
  end

  recurse(root)

  return results
end

--- process gitmodule file ---
local function read_gitmodules(root)
  local modules = {}

  local file = root .. '/.gitmodules'

  if vim.fn.filereadable(file) == 0 then return modules end

  for _, line in ipairs(vim.fn.readfile(file)) do
    local path = line:match '^%s*path%s*=%s*(.+)$'

    if path then modules[path] = true end
  end

  return modules
end

--- refresh Git list ---
function M.refresh()
  local root = M.workspace_root()
  repositories = {}

  --- always insert the workspace repository first ---
  table.insert(repositories, {
    name = vim.fs.basename(root),
    path = root,
    kind = 'workspace',
    relative_path = '.',
  })

  local submodules = read_gitmodules(root)

  --- find nested repositories ---
  for _, repo in ipairs(scan(root)) do
    if submodules[repo.relative_path] then repo.kind = 'submodule' end
    if repo.path ~= root then table.insert(repositories, repo) end
  end

  local previous = current_repo and current_repo.path
  current_repo = repositories[1]

  if previous then
    for _, repo in ipairs(repositories) do
      if repo.path == previous then
        current_repo = repo
        break
      end
    end
  end
end

--- run command in root ---
local function run_in_root(cmd)
  if vim.tbl_isempty(repositories) then M.refresh() end
  local root = M.root()
  if root then vim.cmd('tcd ' .. vim.fn.fnameescape(root)) end
  vim.cmd(cmd)
end

----------------------------------------------------------------------
--------------------------- Git functions ----------------------------
----------------------------------------------------------------------

function M.repositories() return repositories end
function M.current() return current_repo end

function M.select()
  if vim.tbl_isempty(repositories) then M.refresh() end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = 'Repositories',
      finder = finders.new_table {
        results = repositories,
        entry_maker = function(repo)
          return {
            value = repo,
            display = string.format(
              '%s%-30s (%-10s) %s',
              repo == current_repo and '● ' or '  ',
              repo.name,
              repo.kind:gsub('^%l', string.upper),
              repo.relative_path
            ),
            ordinal = repo.name .. ' ' .. repo.path,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry().value
          actions.close(prompt_bufnr)
          current_repo = selection
          vim.notify('Active repository: ' .. selection.name, vim.log.levels.INFO)
        end)
        return true
      end,
    })
    :find()
end

function M.open() run_in_root 'LazyGit' end
function M.diff() run_in_root 'DiffviewOpen' end
function M.close() run_in_root 'DiffviewClose' end
function M.file_history() run_in_root 'DiffviewFileHistory %' end
function M.repo_history() run_in_root 'DiffviewFileHistory' end

function M.graph()
  if vim.tbl_isempty(repositories) then M.refresh() end
  local root = M.root()
  if root then vim.cmd('tcd ' .. vim.fn.fnameescape(root)) end
  vim.cmd 'tabnew'

  require('gitgraph').draw({}, {
    all = true,
    max_count = 5000,
  })

  vim.schedule(
    function()
      vim.keymap.set('n', 'q', '<cmd>tabclose<CR>', {
        buffer = true,
        silent = true,
        desc = 'Close Git Graph',
      })
    end
  )
end

return M
