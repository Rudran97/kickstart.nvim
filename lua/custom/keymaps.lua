local explorer = require 'custom.explorer'
local oil = require 'custom.oil'
local git = require 'custom.git'

vim.keymap.set('n', '<leader><Tab>', explorer.sidebar, { desc = 'Explorer Sidebar' })
vim.keymap.set('n', '<leader>e', explorer.float, { desc = 'Explorer Float' })
vim.keymap.set('n', '-', oil.open, { desc = 'Open parent directory' })
vim.keymap.set('n', '<leader>o', oil.open_float, { desc = 'Oil (Floating)' })
vim.keymap.set('n', '<leader>ws', '<cmd>WorkspaceSave<CR>', { desc = '[W]orkspace [S]ave' })
vim.keymap.set('n', '<leader>wl', '<cmd>WorkspaceLoad<CR>', { desc = '[W]orkspace [L]oad' })
vim.keymap.set('n', '<leader>wd', '<cmd>WorkspaceDelete<CR>', { desc = '[W]orkspace [D]elete' })
vim.keymap.set('n', '<leader>wc', '<cmd>WorkspaceClose<CR>', { desc = '[W]orkspace [C]lose' })
vim.keymap.set('n', '<leader>wr', '<cmd>WorkspaceRelink<CR>', { desc = '[W]orkspace [R]elink' })
vim.keymap.set('n', '<leader>gg', git.open, { desc = 'Lazygit' })
vim.keymap.set('n', '<leader>gd', git.diff, { desc = 'Diff View' })
vim.keymap.set('n', '<leader>gh', git.file_history, { desc = 'File History' })
vim.keymap.set('n', '<leader>gH', git.repo_history, { desc = 'Repository History' })
