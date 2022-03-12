local util = require('reach.util')

local strdisplaywidth = vim.fn.strdisplaywidth

local module = {}

local default = {
  show_icons = true,
  show_current = false,
  show_modified = true,
  force_delete = {},
  filter = nil,
  sort = nil,
  handle = 'auto',
  terminal_char = '\\',
  grayout = true,
  auto_exclude_handles = {},
  previous = {
    enable = true,
    depth = 2,
    chars = { '•' },
    groups = { 'String', 'Comment' },
  },
}

local function validate(options)
  vim.validate({
    options = { options, 'table', true },
  })

  if options then
    local force_delete = options.force_delete
    local terminal_char = options.terminal_char
    local previous = options.previous
    local handle = options.handle
    local auto_exclude_handles = options.auto_exclude_handles

    vim.validate({
      show_icons = { options.show_icons, 'boolean', true },
      show_current = { options.show_current, 'boolean', true },
      show_modified = { options.show_modified, 'boolean', true },
      force_delete = { force_delete, 'table', true },
      filter = { options.filter, 'function', true },
      sort = { options.sort, 'function', true },
      handle = { handle, 'string', true },
      terminal_char = { terminal_char, 'string', true },
      grayout = { options.grayout, 'boolean', true },
      auto_exclude_handles = { auto_exclude_handles, 'table', true },
      previous = { previous, 'table', true },
    })

    if handle then
      vim.validate({
        handle = {
          handle,
          function(value)
            return vim.tbl_contains({ 'auto', 'dynamic', 'bufnr' }, value)
          end,
          '"auto" or "dynamic" or "bufnr"',
        },
      })
    end

    if terminal_char then
      vim.validate({
        terminal_char = {
          terminal_char,
          function(value)
            return type(value) == 'string' and strdisplaywidth(value) == 1
          end,
          'one column width character',
        },
      })
    end

    if auto_exclude_handles then
      vim.validate({
        auto_exclude_handles = {
          auto_exclude_handles,
          function(value)
            return util.every(function(v)
              return type(v) == 'string' and strdisplaywidth(v) == 1
            end, value)
          end,
          'list of characters not to use as handles',
        },
      })
    end

    if force_delete then
      vim.validate({
        force_delete = {
          force_delete,
          function(value)
            return util.every(function(v)
              return type(v) == 'string'
            end, value)
          end,
          'list of strings',
        },
      })
    end

    if previous then
      local chars = previous.chars
      local groups = previous.groups

      vim.validate({
        enable = { previous.enable, 'boolean', true },
        depth = { previous.depth, 'number', true },
        chars = { chars, 'table', true },
        groups = { groups, 'table', true },
      })

      if chars then
        vim.validate({
          chars = {
            chars,
            function(value)
              return util.every(function(v)
                return type(v) == 'string' and strdisplaywidth(v) == 1
              end, value)
            end,
            'list of one column width characters',
          },
        })
      end

      if groups then
        vim.validate({
          groups = {
            chars,
            function(value)
              return util.every(function(v)
                return type(v) == 'string'
              end, value)
            end,
            'list of highlight groups',
          },
        })
      end
    end
  end
end

function module.extend(options)
  validate(options)
  return vim.tbl_deep_extend('force', default, options or {})
end

return module
