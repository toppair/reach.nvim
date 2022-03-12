local icons = require('reach.icons')

local Buffer = {}

function Buffer:new(info)
  local o = {}
  local bo = vim.bo[info.bufnr]

  if icons.status then
    o.icon = icons.get(info.bufnr)
  end

  o.split_path = vim.split(info.name, '/', { trimempty = true })
  o.tail = o.split_path[#o.split_path]
  o.bufnr = info.bufnr
  o.buftype = bo.buftype
  o.deduped = 0
  o.delete_command = 'bdelete ' .. o.bufnr
  o.ext = vim.fn.fnamemodify(o.tail, ':e')
  o.filetype = bo.filetype
  o.modified = info.changed == 1
  o.name = info.name
  o.tailroot = vim.fn.fnamemodify(o.tail, ':t:r')
  o.lastused = info.lastused
  o.unnamed = #info.name < 1
  o.directory = vim.fn.isdirectory(info.name) == 1

  self.__index = self
  return setmetatable(o, self)
end

return Buffer
