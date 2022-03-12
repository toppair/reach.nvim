local status, devicons = pcall(require, 'nvim-web-devicons')

local fnamemodify = vim.fn.fnamemodify

local module = {}

module.status = status

function module.get(bufnr)
  if not status then
    return
  end

  local name = vim.api.nvim_buf_get_name(bufnr)

  if 1 == vim.fn.isdirectory(name) then
    return { '', 'ReachDirectory' }
  end

  local icon, hl = devicons.get_icon(fnamemodify(name, ':t'), fnamemodify(name, ':e'), { default = true })

  return { icon, hl }
end

return module
