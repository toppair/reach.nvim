local f = string.format

local module = {}

function module.deduped_path(buffer)
  return table.concat(buffer.split_path, '/', #buffer.split_path - buffer.deduped)
end

function module.switch_buf(buffer)
  local status = pcall(vim.api.nvim_command, f('buffer %s', buffer.bufnr))

  if not status then
    vim.api.nvim_command(f('view %s', buffer.name))
  end
end

function module.split_buf(buffer, command)
  vim.api.nvim_command(f('%s %s', command, buffer.bufnr))
end

return module
