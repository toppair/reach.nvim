local util = require('reach.util')

local api = vim.api
local buf_is_valid = api.nvim_buf_is_valid
local buf_set_lines = api.nvim_buf_set_lines
local create_buf = api.nvim_create_buf
local open_win = api.nvim_open_win
local strwidth = api.nvim_strwidth
local win_is_valid = api.nvim_win_is_valid
local win_set_config = api.nvim_win_set_config
local win_set_option = api.nvim_win_set_option

local function resolve(view)
  local lines = {}
  local highlights = {}

  for _, parts in pairs(view) do
    local line = ''

    for _, part in pairs(parts) do
      local content = part[1]

      table.insert(highlights, { group = part[2], line = #lines, start = #line, finish = #line + #content })

      line = line .. content
    end

    table.insert(lines, line)
  end

  return lines, highlights
end

local Display = {}

function Display:new()
  local o = {}
  self.config = {
    relative = 'editor',
    style = 'minimal',
    border = 'single',
    focusable = false,
  }
  self.__index = self
  return setmetatable(o, self)
end

function Display:render(view, options)
  local lines, highlights = resolve(view)

  local _, width = util.max(function(line)
    return strwidth(line)
  end, lines)
  local height = #lines

  self:_open({
    width = width,
    height = height,
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
  }, options)

  buf_set_lines(self.bufnr, 0, -1, false, lines)

  self:add_highlights(highlights)

  vim.api.nvim_command('redraw')
end

function Display:_open(config, options)
  if not self.bufnr or not buf_is_valid(self.bufnr) then
    self.bufnr = create_buf(false, true)
  end

  self.config.height = config.height
  self.config.width = config.width

  if self.win and win_is_valid(self.win) then
    if options.force_full_reconfig then
      self.config.row = config.row
      self.config.col = config.col
    end

    win_set_config(self.win, self.config)
  else
    self.config.row = config.row
    self.config.col = config.col

    self.win = open_win(self.bufnr, false, vim.tbl_extend('force', self.config, { noautocmd = true }))

    win_set_option(self.win, 'winhighlight', 'NormalFloat:Normal,FloatBorder:ReachBorder')
  end
end

function Display:add_highlights(highlights)
  for _, hl in pairs(highlights) do
    self:highlight(hl.group, hl.line, hl.start, hl.finish)
  end
end

function Display:highlight(group, line, start, finish)
  vim.api.nvim_buf_add_highlight(self.bufnr, -1, group, line, start, finish)
end

function Display:close()
  if buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true, unload = false })
  end
end

return Display
