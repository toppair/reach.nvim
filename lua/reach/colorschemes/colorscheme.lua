local Colorscheme = {}

function Colorscheme:new(name)
  local o = {}

  o.name = name

  self.__index = self
  return setmetatable(o, self)
end

function Colorscheme:set()
  vim.api.nvim_command('hi clear')
  vim.api.nvim_command('colorscheme ' .. self.name)
end

return Colorscheme
