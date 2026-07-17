return {
  {
    'stevearc/resession.nvim',

    lazy = false,

    dependencies = {
      'nvim-telescope/telescope.nvim',
    },

    opts = {
      autosave = {
        enabled = true,
        interval = 60,
        notify = false,
      },

      load_detail = true,
      load_order = 'modification_time',
    },

    config = function(_, opts)
      --- Modules ---

      local resession = require 'resession'
      local workspace = require 'custom.workspace'

      local pickers = require 'telescope.pickers'
      local finders = require 'telescope.finders'
      local conf = require('telescope.config').values
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      resession.setup(opts)

      --- save original launch directory of nvim ---
      local launch_directory = vim.fn.getcwd()

      ----------------------------------------------------------------------
      ------------------------- Helper Functions ---------------------------
      ----------------------------------------------------------------------

      --- Get current workspace ---
      local function get_current_workspace()
        local info = resession.get_current_session_info()

        if info == nil then return nil end

        if info.dir ~= 'workspace' then return nil end

        return info.name
      end

      local function get_unsaved_buffers()
        local unsaved = {}

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            if vim.bo[buf].modified then
              local name = vim.api.nvim_buf_get_name(buf)

              if name == '' then
                name = '[No Name]'
              else
                -- Show a path relative to the current working directory
                name = vim.fn.fnamemodify(name, ':.')
              end

              table.insert(unsaved, name)
            end
          end
        end

        return unsaved
      end

      local workspace_dir = vim.fn.stdpath 'data' .. '/workspace'

      --- Get the json file linked with current workspace ---
      local function workspace_file(name) return workspace_dir .. '/' .. name .. '.json' end

      --- Read workspace ---
      local function read_workspace(name)
        local path = workspace_file(name)

        if vim.fn.filereadable(path) == 0 then return nil end

        local ok, lines = pcall(vim.fn.readfile, path)
        if not ok then return nil end

        local ok2, json = pcall(vim.json.decode, table.concat(lines, '\n'))
        if not ok2 then return nil end

        return json
      end

      --- Write workspace JSON ---
      local function write_workspace(name, json)
        local path = workspace_file(name)
        local ok, encoded = pcall(vim.json.encode, json)

        if not ok then return false end
        local ok2 = pcall(vim.fn.writefile, vim.split(encoded, '\n'), path)

        return ok2
      end

      --- Workspace info ---
      local function workspace_info(name)
        local json = read_workspace(name)

        if not json then return nil end

        local file = workspace_file(name)
        local stat = vim.uv.fs_stat(file)

        return {
          name = name,
          root = json.global and json.global.cwd or '',
          modified = stat and stat.mtime.sec or 0,
          file = file,
        }
      end

      --- Workspace root ---
      local function workspace_root(name)
        local info = workspace_info(name)

        if info then return info.root end
      end

      local function workspace_exists(name) return vim.fn.filereadable(workspace_file(name)) == 1 end

      local function find_matching_workspaces(root)
        local matches = {}

        local rhs = vim.fn.resolve(root)

        for _, name in ipairs(resession.list { dir = 'workspace' }) do
          local ws_root = workspace_root(name)

          if ws_root then
            local lhs = vim.fn.resolve(ws_root)

            if lhs == rhs then table.insert(matches, name) end
          end
        end

        table.sort(matches)

        return matches
      end

      --- Load a workspace ---
      local function load_workspace(name)
        --- Workspace contains unsaved files ---
        local unsaved = get_unsaved_buffers()

        if #unsaved > 0 then
          local msg

          if #unsaved == 1 then
            msg = 'Cannot load new workspace.\n\n' .. 'Unsaved file:\n\n' .. '  • ' .. unsaved[1]
          else
            msg = string.format('Cannot load new workspace.\n\n%d unsaved files:\n\n', #unsaved)

            for _, file in ipairs(unsaved) do
              msg = msg .. '  • ' .. file .. '\n'
            end
          end

          vim.notify(msg, vim.log.levels.WARN, { title = 'Workspace Load' })
          return
        end

        --- notify plugins a workspace change is about to happen
        require('custom.explorer').workspace_changing(function()
          ----------------------------------------------------
          resession.load(name, {
            dir = 'workspace',
          })

          --- update global workspace information
          local root = workspace_root(name)
          workspace.set_root(root)

          ----------------------------------------------------
          vim.notify(string.format('Loaded workspace "%s"\n\nRoot:\n%s', name, root or 'Unknown'), vim.log.levels.INFO, {
            title = 'Workspace Load',
          })
        end)
      end

      --- Workspace timestamp ---
      local function workspace_timestamp(name)
        local file = workspace_file(name)

        local stat = vim.uv.fs_stat(file)

        if not stat then return '' end

        return os.date('%d-%m-%Y %H:%M', stat.mtime.sec)
      end

      --- Workspace display format ---
      local function workspace_display(name, prefix)
        prefix = prefix or '  '

        local root = workspace_root(name) or ''
        local time = workspace_timestamp(name)

        return string.format('%s%-22s %s    %s', prefix, name, time, vim.fn.fnamemodify(root, ':~'))
      end

      --- for debugging ---
      vim.api.nvim_create_user_command('WorkspaceDebug', function()
        print('cwd =', vim.fn.getcwd())

        for _, ws in ipairs(resession.list { dir = 'workspace' }) do
          print '--------------------------------'
          print('workspace:', ws)
          print('root     :', workspace_root(ws))
        end
      end, {})

      ----------------------------------------------------------------------
      --------------------------- Main Functions ---------------------------
      ----------------------------------------------------------------------

      local function choose_workspace(list)
        local entries = {}

        for _, name in ipairs(list) do
          table.insert(entries, {
            value = name,
            ordinal = name,
            display = workspace_display(name),
          })
        end

        pickers
          .new({}, {
            prompt_title = 'Select Workspace',
            finder = finders.new_table {
              results = entries,
              entry_maker = function(entry)
                return {
                  value = entry.value,
                  display = entry.display,
                  ordinal = entry.ordinal,
                }
              end,
            },

            sorter = conf.generic_sorter {},

            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry().value
                actions.close(prompt_bufnr)
                load_workspace(selection)
              end)

              return true
            end,
          })
          :find()
      end

      local function save_workspace()
        local current = get_current_workspace()

        --- Already attached ---
        if current then
          resession.save(current, {
            dir = 'workspace',
            notify = false,
            attach = true,
          })

          vim.notify('Updated workspace "' .. current .. '"', vim.log.levels.INFO, { title = 'Workspace Save' })

          return
        end

        --- First save ---
        local existing = resession.list {
          dir = 'workspace',
        }

        table.sort(existing)

        local entries = {}

        for _, name in ipairs(existing) do
          table.insert(entries, {
            value = name,
            ordinal = name,
            create = false,
            display = workspace_display(name),
          })
        end

        table.insert(entries, {
          display = '➕  Create New Workspace',
          value = nil,
          ordinal = 'zzzz_create',
          create = true,
        })

        pickers
          .new({}, {
            prompt_title = 'Save Workspace',
            finder = finders.new_table {
              results = entries,
              entry_maker = function(entry)
                return {
                  value = entry,
                  display = entry.display,
                  ordinal = entry.ordinal,
                }
              end,
            },

            sorter = conf.generic_sorter {},

            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry().value

                actions.close(prompt_bufnr)

                --- Existing workspace ---
                if not selection.create then
                  vim.ui.select({ 'No', 'Yes' }, {
                    prompt = 'Overwrite workspace "' .. selection.value .. '" ?',
                  }, function(choice)
                    if choice ~= 'Yes' then return end

                    resession.save(selection.value, {
                      dir = 'workspace',
                      notify = false,
                      attach = true,
                    })

                    vim.notify('Updated workspace "' .. selection.value .. '"', vim.log.levels.INFO, { title = 'Workspace Save' })
                  end)

                  return
                end

                --- create new ---
                vim.ui.input({ prompt = 'Workspace name: ' }, function(name)
                  if not name or name == '' then return end

                  if workspace_exists(name) then
                    vim.notify('Workspace "' .. name .. '" already exists.', vim.log.levels.WARN, { title = 'Workspace Save' })
                    return
                  end

                  resession.save(name, {
                    dir = 'workspace',
                    notify = false,
                    attach = true,
                  })

                  vim.notify('Created workspace "' .. name .. '"', vim.log.levels.INFO, { title = 'Workspace Save' })
                end)
              end)

              return true
            end,
          })
          :find()
      end

      ----------------------------------------------------------------------

      local function close_workspace()
        local current = get_current_workspace()

        --- Attached ---
        if not current then
          vim.notify('No active workspace.', vim.log.levels.WARN, { title = 'Workspace Close' })
          return
        end

        --- Workspace contains unsaved files ---
        local unsaved = get_unsaved_buffers()

        if #unsaved > 0 then
          local msg

          if #unsaved == 1 then
            msg = 'Cannot close workspace.\n\n' .. 'Unsaved file:\n\n' .. '  • ' .. unsaved[1]
          else
            msg = string.format('Cannot close workspace.\n\n%d unsaved files:\n\n', #unsaved)

            for _, file in ipairs(unsaved) do
              msg = msg .. '  • ' .. file .. '\n'
            end
          end

          vim.notify(msg, vim.log.levels.WARN, { title = 'Workspace Close' })
          return
        end

        --- Save workspace ---
        resession.save(current, {
          dir = 'workspace',
          attach = true,
          notify = false,
        })

        vim.notify('Workspace "' .. current .. '" saved.', vim.log.levels.INFO, { title = 'Workspace Close' })
        --- Quit Neovim ---
        vim.cmd 'confirm qall'
      end

      ----------------------------------------------------------------------

      local function telescope_picker(title, entries, callback)
        pickers
          .new({}, {
            prompt_title = title,
            finder = finders.new_table {
              results = entries,
              entry_maker = function(entry)
                return {
                  value = entry.value,
                  display = entry.display,
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

      local function workspace_picker(title, callback)
        local sessions = resession.list {
          dir = 'workspace',
        }

        table.sort(sessions)

        local current = get_current_workspace()

        local entries = {}

        for _, session in ipairs(sessions) do
          local prefix = '  '

          if session == current then prefix = '● ' end

          table.insert(entries, {
            value = session,
            ordinal = session,
            display = workspace_display(session, prefix),
          })
        end

        telescope_picker(title, entries, callback)
      end

      ----------------------------------------------------------------------

      local function relink_workspace()
        local current = get_current_workspace()

        if not current then
          vim.notify('No active workspace.', vim.log.levels.WARN, { title = 'Workspace Relink' })
          return
        end

        local json = read_workspace(current)

        if not json then
          vim.notify('Unable to read workspace.', vim.log.levels.ERROR, { title = 'Workspace Relink' })
          return
        end

        local current_root = workspace_root(current)

        local function update_workspace(new_root)
          json.global.cwd = vim.fn.resolve(new_root)

          if not write_workspace(current, json) then
            vim.notify('Failed to update workspace.', vim.log.levels.ERROR, { title = 'Workspace Relink' })
            return
          end

          --- Keep the workspace attached ---
          vim.schedule(function()
            resession.load(current, {
              dir = 'workspace',
              attach = true,
              notify = false,
            })

            workspace.set_root(new_root)
          end)

          vim.notify(string.format('Workspace "%s"\n\nNew root:\n%s', current, new_root), vim.log.levels.INFO, { title = 'Workspace Relink' })
        end

        local entries = {
          {
            value = launch_directory,
            ordinal = 'launch',
            display = table.concat { 'Use Neovim launch directory', '    ' .. vim.fn.fnamemodify(launch_directory, ':~') },
          },

          {
            value = '__browse__',
            ordinal = 'browse',
            display = table.concat { 'Browse for another directory...', '    Press <Tab> for path completion' },
          },
        }

        telescope_picker(string.format('Relink "%s"', current), entries, function(selection)
          if selection == '__browse__' then
            vim.ui.input({
              prompt = 'New workspace root: ',
              default = current_root,
              completion = 'dir',
            }, function(path)
              if not path or path == '' then return end

              update_workspace(path)
            end)

            return
          end

          update_workspace(selection)
        end)
      end

      ----------------------------------------------------------------------
      ----------------------------------------------------------------------
      ----------------------------------------------------------------------

      vim.api.nvim_create_autocmd('StdinReadPre', {
        callback = function() vim.g.using_stdin = true end,
      })

      vim.api.nvim_create_autocmd('VimEnter', {
        nested = true,
        callback = function()
          if vim.fn.argc(-1) ~= 0 then return end
          if vim.g.using_stdin then return end

          local cwd = vim.fn.getcwd()
          local matches = find_matching_workspaces(cwd)

          --- only one workspace exist ---
          if #matches == 1 then
            vim.schedule(function() load_workspace(matches[1]) end)
            return
          end

          --- when multiple workspace exists with same root ---
          if #matches > 1 then
            vim.schedule(function() choose_workspace(matches) end)
            return
          end

          if vim.g.using_stdin then return end
        end,
      })

      ----------------------------------------------------------------------
      ------------------------------ Commands ------------------------------
      ----------------------------------------------------------------------

      vim.api.nvim_create_user_command('WorkspaceSave', save_workspace, {})
      vim.api.nvim_create_user_command('WorkspaceLoad', function() workspace_picker('Load Workspace', load_workspace) end, {})

      vim.api.nvim_create_user_command('WorkspaceDelete', function()
        workspace_picker('Delete Workspace', function(name)
          local current = get_current_workspace()

          if current == name then
            workspace.clear()
            resession.detach()
          end

          resession.delete(name, {
            dir = 'workspace',
            notify = false,
          })

          vim.notify('Deleted workspace "' .. name .. '"', vim.log.levels.INFO, { title = 'Workspace Delete' })
        end)
      end, {})

      vim.api.nvim_create_user_command('WorkspaceClose', close_workspace, {})
      vim.api.nvim_create_user_command('WorkspaceRelink', relink_workspace, {})

      ----------------------------------------------------------------------
      ------------------------------ Key Maps ------------------------------
      ----------------------------------------------------------------------

      -- vim.keymap.set('n', '<leader>ws', save_workspace, { desc = '[W]orkspace [S]ave' })
      -- vim.keymap.set('n', '<leader>wl', '<cmd>WorkspaceLoad<CR>', { desc = '[W]orkspace [L]oad' })
      -- vim.keymap.set('n', '<leader>wd', '<cmd>WorkspaceDelete<CR>', { desc = '[W]orkspace [D]elete' })
      -- vim.keymap.set('n', '<leader>wc', close_workspace, { desc = '[W]orkspace [C]lose' })
      -- vim.keymap.set('n', '<leader>wr', '<cmd>WorkspaceRelink<CR>', { desc = '[W]orkspace [R]elink' })
    end,
  },
}
