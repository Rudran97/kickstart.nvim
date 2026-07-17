return {
  {
    'stevearc/oil.nvim',
    lazy = false,
    dependencies = {
      'nvim-mini/mini.icons',
    },
    opts = {
      default_file_explorer = true,
      delete_to_trash = false,
      skip_confirm_for_simple_edits = false,
      prompt_save_on_select_new_entry = true,
      cleanup_delay_ms = 2000,
      watch_for_changes = true,
      constrain_cursor = 'editable',
      columns = {
        'icon',
      },
      view_options = {
        show_hidden = true,
        natural_order = true,
        sort = {
          { 'type', 'asc' },
          { 'name', 'asc' },
        },
      },

      ----------------------------------------------------------------------
      --------------------------- Floating Window---------------------------
      ----------------------------------------------------------------------

      float = {
        padding = 2,
        border = 'rounded',
        max_width = 0.90,
        max_height = 0.90,
        preview_split = 'right',
      },

      ----------------------------------------------------------------------
      ------------------------------ Key Maps ------------------------------
      ----------------------------------------------------------------------

      use_default_keymaps = true,

      keymaps = {
        ['q'] = 'actions.close',
        ['<Esc>'] = 'actions.close',
        ['<leader>e'] = false,
      },
    },

    config = function(_, opts)
      local oil = require 'oil'
      oil.setup(opts)
    end,
  },
}
