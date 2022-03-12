local Tabpage = require('reach.tabpages.tabpage')

return function(_)
  return vim.tbl_map(function(tabnr)
    return Tabpage:new(tabnr)
  end, vim.api.nvim_list_tabpages())
end
