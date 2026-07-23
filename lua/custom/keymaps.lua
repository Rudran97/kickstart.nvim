local explorer = require 'custom.explorer'
local oil = require 'custom.oil'
local git = require 'custom.git'
local preview = require 'custom.live-preview'
local term = require 'custom.terminal'
local dbg = require 'custom.debugger'

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

----------------------------------------------------------------------
-------------------------- File Operations ---------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader>d=', '<cmd>CompareCurrentFile<CR>', { desc = '[D]iff [C]urrent File' })
vim.keymap.set('n', '<leader>mp', preview.preview, { desc = '[M]arkdown Live [P]review' })
-- vim.keymap.set('n', '<leader>mc', preview.close, { desc = 'Close Live Preview' })
vim.keymap.set('n', '<leader>mt', '<cmd>RenderMarkdown toggle<CR>', { desc = '[T]oggle Markdown Render' })

----------------------------------------------------------------------
-------------------------- Term Operations ---------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader>tt', term.toggle, { desc = '[T]oggle [T]erminal' })

----------------------------------------------------------------------
-------------------------- Debug Operations --------------------------
----------------------------------------------------------------------

vim.keymap.set('n', '<leader>dc', dbg.continue, { desc = 'Debug: Start/Continue' })
vim.keymap.set('n', '<leader>ds', dbg.step_into, { desc = 'Debug: Step Into' })
vim.keymap.set('n', '<leader>dn', dbg.step_over, { desc = 'Debug: Step Over' })
vim.keymap.set('n', '<leader>do', dbg.step_out, { desc = 'Debug: Step Out' })
vim.keymap.set('n', '<leader>db', dbg.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
vim.keymap.set('n', '<leader>dB', dbg.conditional_breakpoint, { desc = 'Debug: Conditional Breakpoint' })
vim.keymap.set('n', '<leader>dd', dbg.toggle_ui, { desc = 'Debug: Toggle UI' })
vim.keymap.set('n', '<leader>dP', dbg.select_program, { desc = 'Debug: Select Program' })
vim.keymap.set('n', '<leader>dx', dbg.terminate, { desc = 'Debug: Terminate' })
