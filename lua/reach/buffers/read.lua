local util = require('reach.util')

local module = {}

local function match_partial(entries, input)
  return vim.tbl_filter(function(entry)
    return entry.data.handle:sub(1, #input) == input
  end, entries)
end

local function match_exact(entries, input)
  return util.find(function(entry)
    return entry.data.handle == input
  end, entries)
end

function module.read_one(entries, options)
  options = options or {}

  local input = options.input or util.pgetcharstr()

  if not input then
    return
  end

  while true do
    entries = match_partial(entries, input)

    if not entries[1] then
      break
    end

    local exact = match_exact(entries, input)

    if exact and #entries == 1 then
      return exact
    end

    if options.on_input then
      options.on_input(entries, exact, input)
    end

    local char = util.pgetcharstr()

    if not char then
      return
    end

    if char:byte() == 13 then
      return exact
    end

    input = input .. char
  end
end

function module.read_many(entries)
  local input

  local status = pcall(vim.ui.input, { prompt = 'bufnr: ' }, function(value)
    input = value
  end)

  if not status or not input then
    return nil
  end

  local handles = vim.split(input, ' ', { trimepmty = true })

  return vim.tbl_filter(function(entry)
    return vim.tbl_contains(handles, entry.data.handle)
  end, entries)
end

return module
