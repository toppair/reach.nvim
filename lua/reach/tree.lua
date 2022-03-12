local util = require('reach.util')

local Tree = {}
local Edge = {}
local Node = {}

function Edge:new(label)
  local o = {}
  o.label = label
  o.node = Node:new()
  self.__index = self
  return setmetatable(o, self)
end

function Node:new()
  local o = {}
  o.edges = {}
  self.__index = self
  return setmetatable(o, self)
end

function Node:is_leaf()
  return #self.edges == 0
end

function Tree:new()
  local o = {}
  o.root = Node:new()
  self.__index = self
  return setmetatable(o, self)
end

function Tree:get_node(str)
  local node = self.root
  local found = 0
  local nodes = { self.root }
  local labels = {}

  while not node:is_leaf() and found < #str do
    local edge

    for _, e in pairs(node.edges) do
      local common = util.find_common_prefix(e.label, string.sub(str, 1 + found))

      if common == e.label then
        edge = e
        table.insert(labels, e.label)
        break
      end
    end

    if edge then
      table.insert(nodes, edge.node)
      node = edge.node
      found = found + #edge.label
    else
      break
    end
  end

  return nodes[#nodes], found, labels
end

function Tree:insert(str)
  local node, found = self:get_node(str)

  if found ~= #str then
    str = str:sub(found + 1)

    local match

    for i, edge in pairs(node.edges) do
      local common, rest_str, rest_label = util.find_common_prefix(str, edge.label)

      if #common > 0 then
        match = true

        if #rest_label == 0 then
          table.insert(edge.node.edges, Edge:new(rest_str))
        else
          local exist = table.remove(node.edges, i)

          exist.label = rest_label

          local replacement = Edge:new(common)

          table.insert(replacement.node.edges, exist)

          if #rest_str > 0 then
            table.insert(replacement.node.edges, Edge:new(rest_str))
          end

          table.insert(node.edges, i, replacement)
        end
        break
      end
    end

    if not match then
      table.insert(node.edges, Edge:new(str))
    end
  end
end

return Tree
