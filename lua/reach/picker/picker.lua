local Display = require('reach.display')
local util = require('reach.util')

local function make_view(entries)
  local ui_rows = vim.o.lines
  local entries_per_col = ui_rows - math.floor(ui_rows / 5)

  local resolved = vim.tbl_map(function(entry)
    local parts, width = entry:resolve()
    return { parts, width }
  end, entries)

  local view = {}
  local num_cols = 0

  for i = 1, #entries, entries_per_col + 1 do
    local slice = vim.list_slice(resolved, i, i + entries_per_col)

    local _, max = util.max(function(entry)
      return entry[2]
    end, slice)

    for j, entry in pairs(slice) do
      local parts = entry[1]

      table.insert(parts, { string.rep(' ', max - entry[2]), 'Normal' })

      if not view[j] then
        view[j] = {}
      end

      vim.list_extend(view[j], parts)
    end

    num_cols = num_cols + 1
  end

  return view, num_cols
end

local Picker = {}

function Picker:new(entries)
  local o = {}

  o._display = Display:new()
  o.ctx = {}
  o.entries = entries
  o._num_cols = 0

  self.__index = self
  return setmetatable(o, self)
end

function Picker:before(fn)
  self._before = fn
end

function Picker:close()
  self._display:close()
end

function Picker:remove(k, v)
  self.entries = vim.tbl_filter(function(entry)
    return entry.data[k] ~= v
  end, self.entries)
end

function Picker:render(condition)
  local visible = condition and vim.tbl_filter(condition, self.entries) or self.entries

  if self._before then
    self._before(self, visible)
  end

  local view, num_cols = make_view(visible)
  local options = { force_full_reconfig = num_cols ~= self._num_cols }

  self._num_cols = num_cols

  self._display:render(view, options)
end

function Picker:set_ctx(ctx)
  self.ctx = vim.tbl_extend('force', self.ctx, ctx)

  for _, entry in pairs(self.entries) do
    entry:set_state({ ctx = self.ctx })
  end
end

return Picker
