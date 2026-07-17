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
      window = { width = 36 },
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
