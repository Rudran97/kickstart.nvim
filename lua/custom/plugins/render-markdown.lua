--- plugin for native rendering of markdown files ---
return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-mini/mini.nvim',
  },
  ft = { 'markdown', 'html' },
  opts = {
    render_modes = { 'n', 'c', 't' },
    heading = { enabled = true },
    bullet = { enabled = true },
    code = { enabled = true },
    pipe_table = { enabled = true },
    checkbox = { enabled = true },
    -- html = {
    --   -- Turn on / off all HTML rendering.
    --   enabled = true,
    --   -- Additional modes to render HTML.
    --   render_modes = false,
    --   comment = {
    --     -- Useful context to have when evaluating values.
    --     -- | text | text value of the comment node |
    --
    --     -- Turn on / off HTML comment concealing.
    --     conceal = true,
    --     -- Text to inline before the concealed comment.
    --     -- Output is evaluated depending on the type.
    --     -- | function | `value(context)` |
    --     -- | string   | `value`          |
    --     -- | nil      | nothing          |
    --     text = nil,
    --     -- Highlight for the inlined text.
    --     highlight = 'RenderMarkdownHtmlComment',
    --   },
    --   -- HTML tags whose start and end will be hidden and icon shown.
    --   -- The key is matched against the tag name, value type below.
    --   -- | icon            | optional icon inlined at start of tag           |
    --   -- | highlight       | optional highlight for the icon                 |
    --   -- | scope_highlight | optional highlight for item associated with tag |
    --   tag = {},
    -- },
  },
}
