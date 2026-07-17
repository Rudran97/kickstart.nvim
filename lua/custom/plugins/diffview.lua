return {
  'sindrets/diffview.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    keymaps = {
      view = {
        { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      },

      file_history_panel = {
        { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      },

      file_panel = {
        { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close Diffview' } },
      },
    },
  },
}
