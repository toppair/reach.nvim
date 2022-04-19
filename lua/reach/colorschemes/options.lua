local module = {}

local default = {
  filter = (function()
    -- stylua: ignore
    local default = {
      'blue', 'darkblue', 'default', 'delek', 'desert', 'elflord', 'evening', 'industry', 'koehler',
      'morning', 'murphy', 'pablo', 'peachpuff', 'ron', 'shine', 'slate', 'torte', 'zellner',
    }

    return function(name)
      return not vim.tbl_contains(default, name)
    end
  end)(),
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
