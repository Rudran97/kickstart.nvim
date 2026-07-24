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
    'mfussenegger/nvim-dap-python',
    'theHamsta/nvim-dap-virtual-text',

    -- Add your own debuggers here
    -- 'leoluz/nvim-dap-go',
  },
  config = function()
    local dap = require 'dap'
    local dap_py = require 'dap-python'
    local dap_virtual_text = require 'nvim-dap-virtual-text'
    local python = require 'custom.python_debugger'

    dap_py.setup 'python3'
    dap_py.resolve_python = python.resolve_python

    --- configuration for C/C++ debugger ---
    dap.adapters.codelldb = {
      type = 'executable',
      command = 'codelldb',
    }

    dap.adapters.gdb = {
      type = 'executable',
      command = 'gdb',
      args = { '--interpreter=dap' },
    }

    dap_virtual_text.setup {
      enabled = true,
      enabled_commands = true,
      highlight_changed_variables = true,
      highlight_new_as_changed = true,
      show_stop_reason = true,
      commented = false,
      only_first_definition = false,
      all_references = false,
      clear_on_continue = false,
      virt_text_pos = 'inline',
      all_frames = false,
      virt_lines = false,
      virt_text_win_col = nil,
    }

    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {
        -- do not create handlers automatically
        -- if handlers = {} then mason-nvim-dap creates default configurations
        -- which could be broke. Better to configure it manually using dap.configuration.c/cpp/python
        function() end,
      },

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
  end,
}
