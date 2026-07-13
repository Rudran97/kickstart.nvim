----------------------------------------------------------------------------
------------------- VS Code-like scrolling for H/L -------------------------
----------------------------------------------------------------------------
--- Behaviour:
---   • First press of L:
---         Jump cursor to the bottom of the window.
---         (scrolloff automatically leaves 5 lines visible)
---
---   • Holding L:
---         Move down by scroll_speed lines.
---         (scrolloff automatically scrolls the window)
---
---   • H behaves symmetrically.
---------------------------------------------------------------------------

local scroll_speed = 5 -- change this value to have different scroll speed
vim.o.scrolloff = scroll_speed

local function scroll_down()
  local row = vim.fn.winline()
  local height = vim.fn.winheight(0)

  --- cursor not yet near bottom ---
  if row < (height - scroll_speed) then
    vim.cmd 'normal! L'
    return
  end

  --- continue scrolling ---
  vim.cmd('normal! ' .. scroll_speed .. 'j')
end

local function scroll_up()
  local row = vim.fn.winline()

  --- cursor not yet near top ---
  if row > (scroll_speed + 1) then
    vim.cmd 'normal! H'
    return
  end

  --- continue scrolling ---
  vim.cmd('normal! ' .. scroll_speed .. 'k')
end

vim.keymap.set('n', 'L', scroll_down, {
  desc = 'VS Code Scroll Down',
})

vim.keymap.set('n', 'H', scroll_up, {
  desc = 'VS Code Scroll Up',
})
