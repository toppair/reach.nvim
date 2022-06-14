local Buffer = require('reach.buffers.buffer')
local handles = require('reach.buffers.handles')
local u = require('reach.buffers.util')
local util = require('reach.util')
local sort = require('reach.buffers.sort')

local deduped_path = u.deduped_path

local function set_previous_markers(buffers, options)
  local current = vim.api.nvim_get_current_buf()

  local last_used = vim.tbl_filter(function(buffer)
    return buffer.lastused > 0 and buffer.bufnr ~= current
  end, buffers)

  table.sort(last_used, function(a, b)
    return a.lastused > b.lastused
  end)

  local chars = options.chars
  local groups = options.groups

  for i = 1, math.min(options.depth, #last_used) do
    last_used[i].previous_marker = { chars[i] or chars[#chars] or '•', groups[i] or groups[#groups] or 'Comment' }
  end
end

local function dedup(buffer)
  local deduped = buffer.deduped + 1

  if buffer.split_path[#buffer.split_path - deduped] then
    buffer.deduped = deduped
  end
end

return function(options)
  local buffers = {}
  local paths = {}

  for _, info in pairs(vim.fn.getbufinfo({ buflisted = true })) do
    if options.filter and not options.filter(info.bufnr) then
      goto continue
    end

    local buffer = Buffer:new(info)

    local force = util.any(function(v)
      return v == buffer.buftype or v == buffer.filetype
    end, options.force_delete)

    if force then
      buffer.delete_command = 'bdelete! ' .. buffer.bufnr
    end

    if buffer.unnamed then
      buffer.tail = #buffer.filetype > 0 and buffer.filetype or '[No name]'
      table.insert(buffers, buffer)
      goto continue
    end

    local exist

    repeat
      local path = deduped_path(buffer)

      exist = paths[path]

      if exist then
        dedup(buffer)

        if exist.buffer then
          dedup(exist.buffer)
          paths[deduped_path(exist.buffer)] = { buffer = exist.buffer }
          exist.buffer = nil
        end
      else
        paths[path] = { buffer = buffer }
      end
    until not exist

    table.insert(buffers, buffer)

    ::continue::
  end

  if options.previous.enable then
    set_previous_markers(buffers, options.previous)
  end

  if options.handle == 'auto' then
    buffers = sort.sort_priority(buffers, { sort = options.sort })
    handles.assign_auto_handles(
      buffers,
      { auto_handles = options.auto_handles, auto_exclude_handles = options.auto_exclude_handles }
    )
  else
    if type(options.sort) == 'function' then
      table.sort(buffers, function(b1, b2)
        return options.sort(b1.bufnr, b2.bufnr)
      end)
    else
      buffers = sort.sort_default(buffers)
    end

    if options.handle == 'bufnr' then
      handles.assign_bufnr_handles(buffers)
    else
      handles.assign_dynamic_handles(buffers, options)
    end
  end

  return buffers
end
