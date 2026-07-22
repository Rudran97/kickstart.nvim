return {
  'lazyverilog/LazyVerilog',
  submodules = false,
  ft = { 'systemverilog', 'verilog' },
  config = function() require('lazyverilog').setup() end,
}
