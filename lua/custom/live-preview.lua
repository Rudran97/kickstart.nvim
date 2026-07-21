local M = {}

function M.preview()
  if vim.bo.filetype ~= 'markdown' then
    vim.notify('Current buffer is not a Markdown file.', vim.log.levels.WARN)
    return
  end

  if vim.api.nvim_buf_get_name(0) == '' then
    vim.notify('Please save the file first.', vim.log.levels.WARN)
    return
  end

  vim.cmd 'LivePreview start'
end

function M.close()
  pcall(function() vim.cmd 'LivePreview close' end)
end

return M
