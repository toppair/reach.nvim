local Colorscheme = require('reach.colorschemes.colorscheme')

return function(options)
  local names = vim.fn.getcompletion('', 'color')

  if type(options.filter) == 'function' then
    names = vim.tbl_filter(function(name)
      return options.filter(name)
    end, names)
  end

  local index = 1

  return vim.tbl_map(function(name)
    local colorscheme = Colorscheme:new(name)

    if index == 19 then
      index = index + 2
    end

    colorscheme.handle = index > 9 and vim.fn.nr2char(index + 87) or tostring(index)

    index = index + 1

    return colorscheme
  end, names)
end
