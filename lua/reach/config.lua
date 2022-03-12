local module = {}

module.config = {
  notifications = true,
}

function module.setup(config)
  vim.validate({
    config = { config, 'table', true },
  })

  if config then
    vim.validate({
      notifications = { config.notifications, 'boolean', true },
    })
  end

  module.config = vim.tbl_deep_extend('force', module.config, config or {})
end

return module
