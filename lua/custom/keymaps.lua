local explorer = require 'custom.explorer'
local oil = require 'custom.oil'
local git = require 'custom.git'
local diff = require 'custom.compare'

----------------------------------------------------------------------
------------------------------ Explorer ------------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader><Tab>', explorer.sidebar, { desc = 'Explorer Sidebar' })
vim.keymap.set('n', '<leader>e', explorer.float, { desc = '[E]xplorer Float' })
vim.keymap.set('n', '-', oil.open, { desc = '[O]pen parent directory' })
vim.keymap.set('n', '<leader>o', oil.open_float, { desc = '[O]il (Floating)' })

----------------------------------------------------------------------
----------------------------- Workspace ------------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader>ws', '<cmd>WorkspaceSave<CR>', { desc = '[W]orkspace [S]ave' })
vim.keymap.set('n', '<leader>wl', '<cmd>WorkspaceLoad<CR>', { desc = '[W]orkspace [L]oad' })
vim.keymap.set('n', '<leader>wd', '<cmd>WorkspaceDelete<CR>', { desc = '[W]orkspace [D]elete' })
vim.keymap.set('n', '<leader>wc', '<cmd>WorkspaceClose<CR>', { desc = '[W]orkspace [C]lose' })
vim.keymap.set('n', '<leader>wr', '<cmd>WorkspaceRelink<CR>', { desc = '[W]orkspace [R]elink' })

----------------------------------------------------------------------
-------------------------------- Git ---------------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader>gg', git.open, { desc = 'Lazy [G]it' })
vim.keymap.set('n', '<leader>gd', git.diff, { desc = '[D]iff View' })
vim.keymap.set('n', '<leader>gh', git.file_history, { desc = 'File [H]istory' })
vim.keymap.set('n', '<leader>gH', git.repo_history, { desc = 'Repository [H]istory' })
vim.keymap.set('n', '<leader>gb', git.graph, { desc = 'View Git [G]raph' })
vim.keymap.set('n', '<leader>gr', function() require('custom.git').select() end, { desc = 'Select [R]epository' })
vim.keymap.set('n', '<leader>dc', '<cmd>CompareCurrentFile<CR>', { desc = '[D]iff [C]urrent File' })
