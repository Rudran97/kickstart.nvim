return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'MunifTanjim/nui.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    lazy = false,
    opts = {
      close_if_last_window = true,
      popup_border_style = 'rounded',
      enable_git_status = true,
      enable_diagnostics = true,
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = 'disabled',
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      commands = {
        open_tab_background = function(state)
          --- NOTE: using the neo-tree inbuilt open_tab_drop function causes flicker ---

          -- local current_tab = vim.api.nvim_get_current_tabpage()
          -- require('neo-tree.sources.filesystem.commands').open_tab_drop(state)
          --
          -- --- return to the explorer after the tab has opened ---
          -- vim.schedule(function()
          --   if vim.api.nvim_tabpage_is_valid(current_tab) then
          --     vim.api.nvim_set_current_tabpage(current_tab)
          --     require('custom.explorer').focus()
          --   end
          -- end)

          --- manually handling the tab drop functionality ---
          local node = state.tree:get_node()
          if not node or node.type ~= 'file' then return end
          local current = vim.api.nvim_get_current_tabpage()
          vim.cmd('tab drop ' .. vim.fn.fnameescape(node.path))
          vim.api.nvim_set_current_tabpage(current)
          require('custom.explorer').focus()
        end,
      },
      window = {
        width = 36,
        mappings = {
          ['t'] = 'open_tab_background',
        },
      },
      default_component_configs = {
        git_status = {
          symbols = {
            added = 'A',
            modified = 'M',
            deleted = 'D',
            renamed = 'R',
            untracked = '?',
            ignored = 'I',
            unstaged = '!',
            staged = 'S',
            conflict = 'X',
          },
        },
      },
    },

    config = function(_, opts) require('neo-tree').setup(opts) end,
  },
}
