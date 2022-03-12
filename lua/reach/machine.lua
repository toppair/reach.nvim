local Machine = {}

function Machine:new(definition)
  local o = {}
  o._initial = definition.initial
  o._state = definition.state
  o.current = nil
  o.ctx = {}
  self.__index = self
  return setmetatable(o, self)
end

function Machine:init()
  self.current = self._initial
  self._state[self.current].hooks.on_enter(self)
end

function Machine:transition(state)
  local current = self._state[self.current]
  local target = self._state[state]

  assert(target, string.format('No such state: %s', state))
  assert(vim.tbl_contains(current.targets or {}, state), string.format('Invalid target %s for %s', state, self.current))

  if current.hooks.on_exit then
    current.hooks.on_exit(self)
  end

  self.current = state

  target.hooks.on_enter(self)
end

return Machine
