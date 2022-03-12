local module = {}

local default = {
  show_icons = true,
  show_current = false,
}

local function validate(options)
  vim.validate({
    options = { options, 'table', true },
  })

  if options then
    vim.validate({
      show_icons = { options.show_icons, 'boolean', true },
      show_current = { options.show_current, 'boolean', true },
    })
  end
end

function module.extend(options)
  validate(options)
  return vim.tbl_deep_extend('force', default, options or {})
end

return module
