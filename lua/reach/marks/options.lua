local module = {}

local default = {
  filter = function(mark)
    return mark:match('[a-zA-Z]')
  end,
}

local function validate(options)
  vim.validate({
    options = { options, 'table', true },
  })

  if options then
    vim.validate({
      filter = { options.filter, 'function', true },
    })
  end
end

function module.extend(options)
  validate(options)
  return vim.tbl_deep_extend('force', default, options or {})
end

return module
