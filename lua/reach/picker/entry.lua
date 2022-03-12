local strwidth = vim.fn.strwidth

local Entry = {}

function Entry:new(config)
  local o = {}

  o._component = config.component
  o.data = config.data or {}
  o.state = { data = o.data, ctx = {} }

  self.__index = self
  return setmetatable(o, self)
end

function Entry:set_state(state)
  self.state = vim.tbl_extend('force', self.state, state)
end

function Entry:resolve()
  local parts = self._component(self.state)
  local width = 0

  for _, part in pairs(parts) do
    width = width + strwidth(part[1])
  end

  return parts, width
end

return Entry
