local util = require('reach.util')

local insert = table.insert
local f = string.format

local module = {}

module.options = require('reach.marks.options')

local state_to_handle_hl = setmetatable({
  ['DELETING'] = 'ReachHandleDelete',
  ['SPLITTING'] = 'ReachHandleSplit',
}, {
  __index = function()
    return { 'ReachHandleMarkLocal', 'ReachHandleMarkGlobal' }
  end,
})

function module.component(state)
  local mark = state.data
  local ctx = state.ctx

  local parts = {}

  local group_handle = state_to_handle_hl[ctx.state]

  if type(group_handle) == 'table' then
    group_handle = group_handle[mark.global and 2 or 1]
  end

  insert(parts, { f(' %s ', mark.mark), group_handle })

  insert(parts, { mark.content, 'ReachMark' })

  insert(parts, { f(' %s:%s ', mark.line, mark.col), 'ReachMarkLocation' })

  return parts
end

local function read(entries, input)
  input = input or util.pgetcharstr()

  if not input then
    return
  end

  return util.find(function(entry)
    return entry.data.mark == input
  end, entries)
end

local function target_state(input, actions)
  local r = util.replace_termcodes

  if input == r(actions.delete) then
    return 'DELETING'
  end

  if vim.tbl_contains({ r(actions.split), r(actions.vertsplit), r(actions.tabsplit) }, input) then
    return 'SPLITTING'
  end

  return 'SWITCHING'
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

          picker:set_ctx({ state = self.current })
          picker:render()

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
      targets = { 'SWITCHING', 'DELETING', 'SPLITTING', 'CLOSED' },
    },
    SWITCHING = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker
          local input = self.ctx.state.input

          local match = read(picker.entries, input)

          if match then
            vim.api.nvim_feedkeys("'" .. match.data.mark, 'n', false)
          end

          self:transition('CLOSED')
        end,
      },
      targets = { 'CLOSED' },
    },
    DELETING = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker

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
              vim.api.nvim_command('delmarks ' .. match.data.mark)

              picker:remove('mark', match.data.mark)

              if #picker.entries == 0 then
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
    SPLITTING = {
      hooks = {
        on_enter = function(self)
          local picker = self.ctx.picker

          picker:set_ctx({ state = self.current })

          picker:render()

          local match = read(picker.entries)

          if match then
            local action_to_command = {
              split = { 'sbuffer', 'split' },
              vertsplit = { 'vertical sbuffer', 'vertical split' },
              tabsplit = { 'tab sbuffer', 'tabnew' },
            }

            local action = util.find_key(function(value)
              return self.ctx.state.input == util.replace_termcodes(value)
            end, self.ctx.options.actions)
            local split_command = action_to_command[action]

            if match.data.global then
              local row, _, _, name = unpack(vim.api.nvim_get_mark(match.data.mark, {}))
              vim.api.nvim_command(f('%s +%s %s', split_command[2], row, name))
            else
              local row = unpack(vim.api.nvim_buf_get_mark(0, match.data.mark))
              vim.api.nvim_command(f('%s +%s', split_command[1], row))
            end
          end

          self:transition('CLOSED')
        end,
      },
      targets = { 'CLOSED' },
    },
  },
}

return module
