local module = {}

local default = {
  filter = function(mark)
    return mark:match('[a-zA-Z]')
  end,
  actions = {
    split = '-',
    vertsplit = '|',
    tabsplit = ']',
    delete = '<Space>',
  },
}

local function validate(options)
  vim.validate({
    options = { options, 'table', true },
  })

  if options then
    local actions = options.actions

    vim.validate({
      filter = { options.filter, 'function', true },
      actions = { actions, 'table', true },
    })

    if actions then
      vim.validate({
        split = { actions.split, 'string', true },
        vertsplit = { actions.vertsplit, 'string', true },
        tabsplit = { actions.tabsplit, 'string', true },
        delete = { actions.delete, 'string', true },
      })
    end
  end
end

function module.extend(options)
  validate(options)
  return vim.tbl_deep_extend('force', default, options or {})
end

return module
