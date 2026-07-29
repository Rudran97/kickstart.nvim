# Modifications

This is a fork of the original [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim). The goal is to extend the basic neovim `kickstart` framework and setup an environment for Embedded Hardware and Software development applications.

---

## Key Features

* Workspace and Session management
    * Create/Save project workspace tied to a specific root directory. This will help to reopen existing projects and continue from where you left earlier.
    * When opening an existing project, the workspace root will be automatically detected.
    * Relinking existing workspace to another root if needed.
    * Workspace information such as active buffers, tabs, windows and, cursor positions are saved in `~/.local/share/nvim/workspace`.
* File explorer
    * View file structure of the workspace root using floating or sidebar window.
    * Treat the current directory like a buffer to easily modify/create new files and directories.
* Navigation
    * Holding <S-h> and <S-l> will scroll page up/down.
* Language support
    * VHDL: [rust_hdl](https://github.com/vhdl-ls/rust_hdl) is a VHDL language server and analysis library written in Rust. A complete VHDL language server protocol implementation with diagnostics, navigate to symbol, find all references etc. The plugin requires a `vhdl_ls.toml` at the project root describing the file tree.
    * SystemVerilog/Verilog: [lazyVerilog](https://github.com/lazyverilog/LazyVerilog) A language server for verilog and systemverilog. The plugin requires a `lazyverilog.toml` and `vcode.f` files at the project root.
    * Python: `ruff`, `basedpyright` for static analysis, code completion and jump to definition.
    * C/C++: `clangd` for code analysis and jump to definition.
    * Markdown: [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim) to directly render markdown files inside neovim, [live-preview](https://github.com/brianhuster/live-preview.nvim) uses a browser to preview markdown files.
* Git Integration
    * Track, modify, and view git repositories including submodules.
    * Show git-diff between commits.
* Terminal
    * Intergrated terminal to execute commands.
    * Capable of creating multiple terminal instances across workspaces.
* Debug
    * Debug environment for C/C++ and python.
    * Virtual inline text after evaluating expressions (require Neovim >= v0.12.x).

---

## Required Plugins

* Workspace and Session
    * [resession](https://github.com/stevearc/resession.nvim) primary plugin to manage workspaces and sessions.
* File explorer
    * [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) is used to browse the current workspace using a sidebar/floating window. Also shows the status if the current workspace contain a git repository.
    * [oil](https://github.com/stevearc/oil.nvim) is used to edit the file system like a normal buffer.
* Language
    * [lazyVerilog](https://github.com/lazyverilog/LazyVerilog) for Verilog and SystemVerilog.
    * [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim) and [live-preview](https://github.com/brianhuster/live-preview.nvim) for Markdown files.
    * Other LSP configurations can be found in [init.lua](./init.lua).
* Git
    * [lazygit](https://github.com/kdheepak/lazygit.nvim) plugin for calling lazygit from within Neovim. ***Note: requires `lazygit` to be installed in the system.***
    * [gitgraph](https://github.com/isakbm/gitgraph.nvim) plugin to view repository structure.
    * [diffview](https://github.com/sindrets/diffview.nvim) plugin for easily cycling through diffs for all modified files in a git repository.
* Terminal
    * [floaterm](https://github.com/nvzone/floaterm) plugin to manage Neovim terminal buffers.
* Debug
    * [nvim-dap](https://github.com/mfussenegger/nvim-dap) plugin for debug environment. ***Note: use `codelldb` for C/C++ debugging as dap-gdb has some compatibility issues. To debug python scripts, install `debugpy` in the system:***
    ```python
    python -m pip install debugpy
    ```

---

## Keymaps

Some additional keymaps are as follows:

* Workspace

| Keymap         | Description                                |
| :---           | :---                                       |
| \<leader\>ws   | Save workspace.                            |
| \<leader\>wl   | Load workspace.                            |
| \<leader\>wd   | Delete workspace.                          |
| \<leader\>wc   | Close workspace.                           |
| \<leader\>wr   | Relink workspace to a new root.            |

* File explorer

| Keymap            | Description                                                 |
| :---              | :---                                                        |
| \<leader\>\<Tab\> | Toggle explorer sidebar.                                    |
| \<leader\>e       | Toggle explorer floating window.                            |
| -                 | Open current file's parent directory as an editable buffer. |
| \<leader\>o       | Open workspace root directory as an editable buffer.        |

* Git

| Keymap         | Description                                   |
| :---           | :---                                          |
| \<leader\>gg   | Open LazyGit interface.                       |
| \<leader\>gd   | Open git diff-view.                           |
| \<leader\>gh   | View file commit history.                     |
| \<leader\>gH   | View repository history.                      |
| \<leader\>gb   | View git branch.                              |
| \<leader\>gr   | Select repositories in the current workspace. |

* File operations

| Keymap            | Description                                |
| :---              | :---                                       |
| \<leader\>\<d=\>  | Compare current file with another file.    |
| \<leader\>mp      | Open Markdown live-preview on the browser. |
| \<leader\>mt      | Toggle Markdown render inside Neovim.      |

* Terminal operations

| Keymap            | Description                     |
| :---              | :---                            |
| \<leader\>\<tt\> | Toggle floating terminal window. |

* Git

| Keymap         | Description                                            |
| :---           | :---                                                   |
| \<leader\>dc   | Start debugging or continue until the next breakpoint. |
| \<leader\>ds   | Step into.                                             |
| \<leader\>dn   | Step over.                                             |
| \<leader\>do   | Step out.                                              |
| \<leader\>db   | Toggle breakpoint on current line.                     |
| \<leader\>dB   | Toggle conditional breakpoint on current line.         |
| \<leader\>dd   | Toggle debug UI.                                       |
| \<leader\>dP   | Select program to debug.                               |
| \<leader\>dx   | Terminate debug.                                       |
| \<leader\>dT   | Select target debugger.                                |
