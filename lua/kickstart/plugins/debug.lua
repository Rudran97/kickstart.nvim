-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

---@module 'lazy'
---@type LazySpec
return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    -- 'leoluz/nvim-dap-go',
  },
  -- keys = {
  --   -- Basic debugging keymaps, feel free to change to your liking!
  --   { '<leader>dc', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
  --   { '<leader>ds', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
  --   { '<leader>dn', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
  --   { '<leader>do', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
  --   { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
  --   { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Set Breakpoint' },
  --   -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
  --   { '<leader>dd', function() require('dapui').toggle() end, desc = 'Debug: See last session result.' },
  -- },
  config = function()
    local dap = require 'dap'

    --- configuration for python debugger ---
    dap.adapters.python = {
      type = 'executable',
      command = 'python3',
      args = {
        '-m',
        'debugpy.adapter',
      },
    }

    dap.configurations.python = {
      {
        type = 'python',
        request = 'launch',
        name = 'Launch current file',
        program = '${file}',
        console = 'integratedTerminal',
        justMyCode = true,
      },
    }
    ---

    --- configuration for C/C++ debugger ---
    local debugger = require 'custom.debugger'

    dap.configurations.cpp = {
      {
        name = 'Launch executable',
        type = 'gdb',
        request = 'launch',

        program = debugger.program,

        cwd = '${workspaceFolder}',
        stopAtBeginningOfMainSubprogram = false,
        args = {},
      },
    }
    ---

    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        -- 'delve',
        'debugpy',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      ---@diagnostic disable-next-line: missing-fields
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    --- cleanup the [dap-repl-xx] buffer ---
    local function cleanup_dap()
      dap.repl.close()

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[buf].buftype == 'prompt' then
          local name = vim.api.nvim_buf_get_name(buf)

          if name:match '^%[dap%-repl' then vim.api.nvim_buf_delete(buf, { force = true }) end
        end
      end
    end

    --- open debug environment in a new tab ---
    local original_tab = nil
    local debug_tab = nil

    dap.listeners.after.event_initialized['dap_tab'] = function()
      original_tab = vim.api.nvim_get_current_tabpage()

      vim.cmd 'tabnew'

      debug_tab = vim.api.nvim_get_current_tabpage()

      dapui.open()
    end
    local function close_debug_session()
      dapui.close()

      if debug_tab and vim.api.nvim_tabpage_is_valid(debug_tab) then
        vim.api.nvim_set_current_tabpage(debug_tab)
        vim.cmd 'tabclose'
      end

      if original_tab and vim.api.nvim_tabpage_is_valid(original_tab) then vim.api.nvim_set_current_tabpage(original_tab) end
    end

    dap.listeners.before.event_terminated['dap_tab'] = close_debug_session
    dap.listeners.before.event_exited['dap_tab'] = close_debug_session
    dap.listeners.before.event_terminated['dap_cleanup'] = cleanup_dap
    dap.listeners.before.event_exited['dap_cleanup'] = cleanup_dap

    -- Install golang specific config
    -- require('dap-go').setup {
    --   delve = {
    --     -- On Windows delve must be run attached or it crashes.
    --     -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
    --     detached = vim.fn.has 'win32' == 0,
    --   },
    -- }
  end,
}
