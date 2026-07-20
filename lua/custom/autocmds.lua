vim.api.nvim_create_autocmd({ 'WinEnter', 'BufWinEnter' }, {
  callback = function()
    if vim.wo.diff then
      vim.wo.foldmethod = 'manual'
      vim.cmd 'silent! normal! zR'
    end
  end,
})
