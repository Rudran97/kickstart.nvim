local M = {}

function M.open() vim.cmd 'Oil' end
function M.open_float() require('oil').open_float() end

return M
