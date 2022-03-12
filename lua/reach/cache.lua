local util = require('reach.util')

local cache_dir = vim.fn.stdpath('cache')
local cache_filename = 'reach_cache'
local cache_file = table.concat({ cache_dir, cache_filename }, '/')

local module = {}

local schema = {
  directories = {},
  version = 1,
}

local directories, cache_cwd = {}, nil

local function validate(cache)
  if type(cache.directories) ~= 'table' then
    return
  end

  for _, directory in pairs(cache.directories) do
    if type(directory.cwd) ~= 'string' or type(directory.cache) ~= 'table' then
      return
    end

    local auto_priority = directory.cache.auto_priority

    if auto_priority then
      if type(auto_priority) ~= 'table' then
        return
      end

      for _, item in pairs(auto_priority) do
        if type(item.name) ~= 'string' or type(item.priority) ~= 'string' then
          return
        end
      end
    end
  end

  return true
end

local function read_cache()
  if 0 == vim.fn.filereadable(cache_file) then
    vim.fn.writefile({ vim.json.encode(schema) }, cache_file)
    return vim.deepcopy(schema)
  end

  local status, decoded = pcall(vim.json.decode, vim.fn.readfile(cache_file)[1])

  if not status or not validate(decoded) then
    vim.fn.writefile({ vim.json.encode(schema) }, cache_file)
    return vim.deepcopy(schema)
  end

  return decoded
end

function module.setup()
  vim.api.nvim_command('autocmd DirChanged * lua require("reach.cache").load()')
  vim.api.nvim_command('autocmd VimLeavePre * lua require("reach.cache").persist()')
  module.load()
end

function module.load()
  local cwd = vim.fn.getcwd()

  local directory = util.find(function(directory)
    return directory.cwd == cwd
  end, directories)

  if not directory then
    local cache = read_cache()

    directory = util.find(function(dir)
      return dir.cwd == cwd
    end, cache.directories)

    if not directory then
      directory = { cwd = cwd, cache = { auto_priority = {} } }
    end

    table.insert(directories, directory)
  end

  cache_cwd = directory.cache
end

function module.persist()
  local cache = read_cache()

  for _, directory in pairs(directories) do
    local dir_cache = directory.cache

    for key, value in pairs(dir_cache) do
      if type(value) == 'table' and #value == 0 then
        dir_cache[key] = nil
      end
    end

    if 0 == #vim.tbl_keys(dir_cache) then
      cache.directories = vim.tbl_filter(function(dir)
        return dir.cwd ~= directory.cwd
      end, cache.directories)

      goto continue
    end

    for _, dir in pairs(cache.directories) do
      if dir.cwd == directory.cwd then
        dir.cache = dir_cache
        goto continue
      end
    end

    table.insert(cache.directories, directory)

    ::continue::
  end

  vim.fn.writefile({ vim.json.encode(cache) }, cache_file)
end

function module.get(key)
  return vim.deepcopy(cache_cwd[key])
end

function module.set(key, value)
  cache_cwd[key] = vim.deepcopy(value)
end

return module
