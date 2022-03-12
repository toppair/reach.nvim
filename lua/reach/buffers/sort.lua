local auto_handles = require('reach.buffers.constant').auto_handles
local cache = require('reach.cache')
local util = require('reach.util')

local module = {}

function module.sort_default(buffers)
  local details = {}

  for _, buffer in pairs(buffers) do
    local sp = buffer.split_path
    local path = table.concat(sp, '', #sp - buffer.deduped, #sp - 1):gsub('%W', '')

    details[buffer.bufnr] = { buffer.tailroot, buffer.ext, path }
  end

  table.sort(buffers, function(a, b)
    local da = details[a.bufnr]
    local db = details[b.bufnr]

    return da[2] == db[2] and (da[1] == db[1] and da[3] < db[3] or da[1] < db[1]) or da[2] < db[2]
  end)

  return buffers
end

function module.sort_priority(buffers, options)
  local name_to_priority = util.reduce(function(item, acc)
    acc[item.name] = item.priority
    return acc
  end, cache.get('auto_priority'), {})

  local prioritized = {}
  local rest = {}

  for _, buffer in pairs(buffers) do
    buffer.priority = name_to_priority[buffer.name]
    table.insert(buffer.priority and prioritized or rest, buffer)
  end

  table.sort(prioritized, function(a, b)
    return util.index_of(a.priority, auto_handles) < util.index_of(b.priority, auto_handles)
  end)

  if options and type(options.sort) == 'function' then
    table.sort(rest, function(b1, b2)
      return options.sort(b1.bufnr, b2.bufnr)
    end)
  else
    rest = module.sort_default(rest)
  end

  return vim.list_extend(prioritized, rest)
end

return module
