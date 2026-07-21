return {
  'nvzone/floaterm',
  dependencies = {
    'nvzone/volt',
  },
  opts = {
    border = true,
    autoinsert = true,
    size = {
      h = 70,
      w = 80,
    },
    -- to use, make this func(buf)
    mappings = {
      -- sidebar = function(buf)
      --   vim.keymap.set('n', 'q', function() require('floaterm').toggle() end, {
      --     buffer = buf,
      --     silent = true,
      --     desc = 'Hide Terminal',
      --   })
      -- end,

      sidebar = function(buf)
        vim.keymap.set('n', '<ESC>', function() require('floaterm').toggle() end, { buffer = buf })
      end,

      term = function(buf)
        vim.keymap.set('n', '<ESC>', function() require('floaterm').toggle() end, { buffer = buf })
      end,
    },
    terminals = {
      { name = 'Terminal' },
    },
  },
}
