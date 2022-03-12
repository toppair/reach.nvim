local config = require('reach.config')

local module = {}

function module.notify(msg, level, force)
  if config.config.notifications or force then
    vim.api.nvim_notify(msg, level or vim.log.levels.INFO, {})
  end
end

return module
