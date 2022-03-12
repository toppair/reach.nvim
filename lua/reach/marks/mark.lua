local Mark = {}

function Mark:new(mark, line, col, content)
  local o = {}

  o.mark = mark
  o.line = line
  o.col = col
  o.content = content
  o.global = mark:byte() == mark:upper():byte()

  self.__index = self
  return setmetatable(o, self)
end

return Mark
