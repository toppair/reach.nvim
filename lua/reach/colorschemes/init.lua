local util = require('reach.util')

local insert = table.insert
local f = string.format

local module = {}

module.options = require('reach.colorschemes.options')

function module.component(state)
  local scheme = state.data
  local parts = {}

  insert(parts, { f(' %s ', scheme.handle), 'ReachHandleBuffer' })
  insert(parts, { f(' %s ', scheme.name), 'Normal' })

  return parts
end

module.machine = {
  initial = 'OPEN',
  state = {
    CLOSED = {
      hooks = {
        on_enter = function(self)
          self.ctx.picker:close()
        end,
      },
    },
    OPEN = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker

          picker:render()

          local match

          repeat
            local input = util.pgetcharstr()

            if not input then
              return self:transition('CLOSED')
            end

            match = util.find(function(entry)
              return entry.data.handle == input
            end, picker.entries)

            if match then
              picker:close()
              match.data:set()
            end

            picker:render()

          until not match

          self:transition('CLOSED')
        end,
      },
      targets = { 'CLOSED' },
    },
  },
}

return module
