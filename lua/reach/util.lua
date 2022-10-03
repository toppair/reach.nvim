local module = {}

function module.any(fn, t)
  for _, value in pairs(t) do
    if fn(value) then
      return true
    end
  end

  return false
end

function module.count(fn, t, threshold)
  local count = 0

  for _, value in pairs(t) do
    if fn(value) then
      count = count + 1

      if count == threshold then
        return count
      end
    end
  end

  return count
end

function module.every(fn, t)
  for _, value in pairs(t) do
    if not fn(value) then
      return false
    end
  end

  return true
end

function module.find(fn, t)
  for i, value in pairs(t) do
    if fn(value) then
      return value, i
    end
  end
end

function module.find_common_prefix(s1, s2)
  local common = ''

  for i = 1, math.max(#s1, #s2) do
    local char = s1:sub(i, i)

    if char ~= s2:sub(i, i) then
      return common, s1:sub(i), s2:sub(i)
    end

    common = common .. char
  end

  return common, '', ''
end

function module.for_each(fn, t)
  for _, value in pairs(t) do
    fn(value)
  end
end

function module.index_of(val, t)
  for i, value in ipairs(t) do
    if (type(val) == 'function' and val(value)) or val == value then
      return i
    end
  end
end

function module.find_key(val, t)
  for key, value in pairs(t) do
    if (type(val) == 'function' and val(value)) or val == value then
      return key
    end
  end
end

function module.max(fn, t)
  local max = { nil, 0 }

  for _, value in pairs(t) do
    local result = fn(value)

    if result > max[2] then
      max = { value, result }
    end
  end

  return unpack(max)
end

function module.reduce(fn, t, acc)
  for _, value in pairs(t) do
    acc = fn(value, acc)
  end

  return acc
end

function module.reverse(t)
  local output = {}

  for i = #t, 1, -1 do
    table.insert(output, t[i])
  end

  return output
end

function module.pgetcharstr()
  local status, char = pcall(vim.fn.getcharstr)
  if status then
    return char
  end
end

function module.replace_termcodes(input)
  return vim.api.nvim_replace_termcodes(input, true, true, true)
end

return module
