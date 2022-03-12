local Mark = require('reach.marks.mark')

return function(options)
  local output = vim.api.nvim_exec('marks', true)
  local rows = vim.split(output, '\n', { trimempty = true })

  table.remove(rows, 1)

  local marks = {}

  for _, row in pairs(rows) do
    local parts = vim.split(row, '[ \t]+', { trimempty = true })
    local mark, line, col = unpack(parts, 1, 3)

    table.insert(marks, Mark:new(mark, line, col, table.concat(parts, ' ', 4)))
  end

  if type(options.filter) == 'function' then
    return vim.tbl_filter(function(m)
      return options.filter(m.mark)
    end, marks)
  end

  return marks
end
