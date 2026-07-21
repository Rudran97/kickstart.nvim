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

      term = function(buf)
        -- Future custom terminal mappings go here.
      end,
    },
    terminals = {
      { name = 'Terminal' },
    },
  },
}
