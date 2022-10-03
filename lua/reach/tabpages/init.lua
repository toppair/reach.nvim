local icons = require('reach.icons')
local util = require('reach.util')

local notify = require('reach.helpers').notify

local insert = table.insert
local f = string.format

local module = {}

module.options = require('reach.tabpages.options')

local state_to_handle_hl = setmetatable({
  ['DELETING'] = 'ReachHandleDelete',
}, {
  __index = function()
    return 'ReachHandleTabpage'
  end,
})

function module.component(state)
  local tabpage = state.data
  local ctx = state.ctx

  local parts = {}

  insert(parts, { f(' %s ', state.data:handle()), state_to_handle_hl[ctx.state] })

  if state.icons then
    table.insert(parts, { ' ', 'Normal' })

    for i = 1, ctx.max_icon_count do
      local icon, hl = unpack(state.icons[i] or { ' ', 'Normal' })
      table.insert(parts, { f('%s ', icon), hl })
    end

    table.insert(parts, { ' ', 'Normal' })
  end

  insert(parts, { f('%s window%s ', #tabpage.wins, #tabpage.wins > 1 and 's' or ''), 'Comment' })

  return parts
end

local function read(entries, input)
  input = input or util.pgetcharstr()

  if not input then
    return
  end

  return util.find(function(entry)
    return entry.data:handle() == input
  end, entries)
end

local function target_state(input, actions)
  if input == util.replace_termcodes(actions.delete) then
    return 'DELETING'
  end

  return 'SWITCHING'
end

local function hide_current()
  local current = vim.api.nvim_get_current_tabpage()

  return function(entry)
    return entry.data.tabnr ~= current
  end
end

local function collect_icons(tabpage)
  local parts = {}

  for _, win in pairs(tabpage.wins) do
    local icon = icons.get(vim.api.nvim_win_get_buf(win))

    local present = util.any(function(p)
      return p[1] == icon[1]
    end, parts)

    if not present then
      insert(parts, icon)
    end
  end

  return parts
end

local function set_icon_count(picker, entries)
  local max_icon_count = 0

  for _, entry in pairs(entries) do
    local icns = entry.state.icons

    if max_icon_count < #icns then
      max_icon_count = #icns
    end
  end

  picker:set_ctx({ max_icon_count = max_icon_count })
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

          if icons.status and self.ctx.options.show_icons then
            for _, entry in pairs(picker.entries) do
              entry:set_state({ icons = collect_icons(entry.data) })
            end

            picker:before(set_icon_count)
          end

          picker:set_ctx({ state = self.current })
          picker:render(not self.ctx.options.show_current and hide_current() or nil)

          local input = util.pgetcharstr()

          if not input then
            return self:transition('CLOSED')
          end

          self.ctx.state = {
            input = input,
          }

          self:transition(target_state(self.ctx.state.input, self.ctx.options.actions))
        end,
      },
      targets = { 'SWITCHING', 'DELETING', 'CLOSED' },
    },
    SWITCHING = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker
          local input = self.ctx.state.input

          local match = read(picker.entries, input)

          if match then
            vim.api.nvim_feedkeys(f('%sgt', match.data:number()), 'n', false)
          end

          self:transition('CLOSED')
        end,
      },
      targets = { 'CLOSED', 'DELETING' },
    },
    DELETING = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker

          if #picker.entries < 2 then
            notify('Cannot close last tabpage', vim.log.levels.WARN)
            return self:transition('CLOSED')
          end

          picker:set_ctx({ state = self.current })
          picker:render()

          local match

          repeat
            local input = util.pgetcharstr()

            if not input then
              return self:transition('CLOSED')
            end

            if input == util.replace_termcodes(self.ctx.options.actions.delete) then
              return self:transition('OPEN')
            end

            match = read(picker.entries, input)

            if match then
              vim.api.nvim_command(f('tabclose %s', match.data:number()))

              picker:remove('tabnr', match.data.tabnr)

              if #picker.entries < 2 then
                break
              end

              picker:render()
            end

          until not match

          self:transition('CLOSED')
        end,
      },
      targets = { 'CLOSED', 'OPEN' },
    },
  },
}

return module
