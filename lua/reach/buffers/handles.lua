local Tree = require('reach.tree')
local util = require('reach.util')

local deduped_path = require('reach.buffers.util').deduped_path

local module = {}

function module.assign_bufnr_handles(buffers)
  for _, buffer in pairs(buffers) do
    buffer.handle = tostring(buffer.bufnr)
  end
end

function module.assign_auto_handles(buffers, options)
  local auto_handles = options.auto_handles
  local index = 1

  for _, buffer in pairs(buffers) do
    while vim.tbl_contains(options.auto_exclude_handles, auto_handles[index]) do
      index = index + 1
    end

    buffer.handle = auto_handles[index] or auto_handles[#auto_handles]

    index = index + 1
  end
end

function module.assign_dynamic_handles(buffers, options)
  local terminals, deduped, undeduped, unnamed, directories, tree = {}, {}, {}, {}, {}, Tree:new()

  local function is_unique(handle)
    return 1 == util.count(function(b)
      return b.tail:sub(1, 1) == handle
    end, buffers, 2)
  end

  for _, buffer in pairs(buffers) do
    local insert = table.insert

    if buffer.buftype == 'terminal' then
      insert(terminals, buffer)
      goto continue
    elseif buffer.unnamed then
      insert(unnamed, buffer)
      goto continue
    elseif buffer.directory then
      insert(directories, buffer)
      goto continue
    end

    buffer.handle = buffer.tail:sub(1, 1)

    if is_unique(buffer.handle) then
      goto continue
    end

    if buffer.deduped > 0 then
      insert(deduped, buffer)
    else
      tree:insert(buffer.tailroot)
      insert(undeduped, buffer)
    end

    ::continue::
  end

  -- TERMINALS
  local terminal_char = options.terminal_char or '\\'

  if #terminals == 1 then
    terminals[1].handle = terminal_char
  else
    local term = 1

    for _, buffer in pairs(terminals) do
      buffer.handle = terminal_char .. (term > 9 and vim.fn.nr2char(term + 87) or term)
      term = term + 1
    end
  end

  -- UNDEDUPED

  local details = {}

  for _, buffer in pairs(undeduped) do
    local _, _, labels = tree:get_node(buffer.tailroot)
    local src = buffer.tailroot:sub(2) .. table.concat(util.reverse(buffer.split_path), '')

    if #labels > 1 then
      src = labels[#labels] .. src
    end

    local split = vim.split(labels[#labels], '%W')

    if split[2] then
      src = split[2]:sub(1, 1) .. src
    end

    table.insert(details, { buffer, labels, src:gsub('%W', '') })
  end

  table.sort(details, function(a, b)
    return #a[2] == #b[2] and a[1].tail < b[1].tail or #a[2] > #b[2]
  end)

  local function gen_handle(primary, src)
    src = src .. 'abcdefghijklmnopqrstuwxyzABCDEFGHIJKLMNOPQRSTUWXYZ1234567890!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'

    for _, char in pairs(vim.split(src, '')) do
      local handle = (primary or '') .. char

      local exists = util.any(function(buffer)
        if not buffer.handle then
          return
        end

        return buffer.handle:sub(1, #handle) == handle
      end, buffers)

      if not exists then
        return handle
      end
    end

    return primary .. src:sub(#src)
  end

  for _, item in pairs(details) do
    local buffer, _, src = unpack(item)
    local handle = buffer.handle .. src:sub(1, 1)

    local exists = util.find(function(i)
      return i[1].handle == handle
    end, details)

    if exists then
      local exist_buffer = exists[1]

      if exist_buffer.low_priority then
        exist_buffer.handle = gen_handle(buffer.handle, exists[3])
      else
        buffer.low_priority = true
        handle = gen_handle(buffer.handle, src)
      end
    end

    buffer.handle = handle
  end

  -- DEDUPED

  table.sort(deduped, function(a, b)
    local at = a.tailroot
    local bt = b.tailroot

    return at == bt and #deduped_path(a) < #deduped_path(b) or #at < #bt
  end)

  for _, buffer in pairs(deduped) do
    local sp = buffer.split_path

    buffer.handle = gen_handle(buffer.handle, table.concat(sp, '', #sp - buffer.deduped, #sp - 1):gsub('%W', ''))
  end

  -- DIRECTORIES

  for _, buffer in pairs(directories) do
    buffer.handle = gen_handle('/', buffer.tail)
  end

  -- UNNAMED

  for _, buffer in pairs(unnamed) do
    buffer.handle = gen_handle(nil, '')
  end
end

return module
