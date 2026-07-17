return {
  'isakbm/gitgraph.nvim',
  dependencies = {
    'sindrets/diffview.nvim',
  },
  opts = {
    hooks = {
      on_select_commit = function(commit) vim.cmd('DiffviewOpen ' .. commit.hash .. '^!') end,
      on_select_range_commit = function(from, to) vim.cmd('DiffviewOpen ' .. from.hash .. '~1..' .. to.hash) end,
    },
  },
}
