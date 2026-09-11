return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  config = function()
    local mc = require 'multicursor-nvim'
    mc.setup()

    mc.addKeymapLayer(function(layer)
      layer('n', '<Esc>', function()
        if mc.cursorsEnabled() then mc.clearCursors() end
      end)
    end)
  end,
}
