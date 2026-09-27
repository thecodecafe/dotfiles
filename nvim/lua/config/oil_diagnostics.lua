local M = {}

local MAX_FILES_PER_SCAN = 100
local MAX_CANDIDATES_PER_SCAN = 1000
local OPEN_INTERVAL_MS = 100
local MAX_FILE_SIZE = 1024 * 1024

local generation = 0
local queue_timer
local active_oil_buffer
local records = {}
local buffers = {}
local refreshing = false
local setup_done = false

local function normalize(path)
  return vim.fs.normalize(path)
end

local function is_hidden(path)
  local name = path:match("([^/]+)$") or path
  return name:sub(1, 1) == "."
end

local function stop_queue()
  generation = generation + 1
  if queue_timer then
    queue_timer:stop()
    queue_timer:close()
    queue_timer = nil
  end
  return generation
end

local function get_filetype(path)
  return vim.filetype.match({ filename = path })
end

local function relative_to(root, path)
  if not root then
    return nil
  end
  local relative = vim.fs.relpath(normalize(root), normalize(path))
  if not relative or relative == ".." or relative:match("^%.%./") then
    return nil
  end
  return relative
end

local function matching_clients(path, filetype, clients)
  local matches = {}
  for _, client in ipairs(clients or vim.lsp.get_clients()) do
    local root = client.root_dir or client.config.root_dir
    local filetypes = client.config.filetypes or {}
    local supports_filetype = vim.tbl_contains(filetypes, filetype)
    local running = not client:is_stopped()
    if running and supports_filetype and relative_to(root, path) then
      table.insert(matches, client)
    end
  end
  return matches
end

local function append_regular_file(paths, path, clients, limit)
  if #paths >= limit then
    return
  end
  if is_hidden(path) then
    return
  end
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "file" and stat.size <= MAX_FILE_SIZE then
    local filetype = get_filetype(path)
    if filetype then
      local matches = matching_clients(path, filetype, clients)
      if #matches > 0 then
        table.insert(paths, { path = normalize(path), filetype = filetype, clients = matches })
      end
    end
  end
end

local function append_child_files(paths, child_dir, clients, limit)
  local dir_stat = vim.uv.fs_lstat(child_dir)
  if not dir_stat or dir_stat.type ~= "directory" then
    return
  end
  local scan = vim.uv.fs_scandir(child_dir)
  if not scan then
    return
  end
  while true do
    if #paths >= limit then
      break
    end
    local name, entry_type = vim.uv.fs_scandir_next(scan)
    if not name then
      break
    end
    if entry_type == "file" and name:sub(1, 1) ~= "." then
      append_regular_file(paths, child_dir .. "/" .. name, clients, limit)
    end
  end
end

function M.collect_paths(bufnr)
  local oil = require("oil")
  local current_dir = oil.get_current_dir(bufnr)
  if not current_dir then
    return nil, "not an Oil directory buffer"
  end
  current_dir = normalize(current_dir)
  local clients = vim.lsp.get_clients()

  local direct_files = {}
  local child_dirs = {}
  for line = 1, vim.api.nvim_buf_line_count(bufnr) do
    local entry = oil.get_entry_on_line(bufnr, line)
    if entry and entry.name and entry.name ~= ".." and entry.name:sub(1, 1) ~= "." then
      local path = current_dir .. "/" .. entry.name
      if entry.type == "file" then
        append_regular_file(direct_files, path, clients, MAX_CANDIDATES_PER_SCAN + 1)
      elseif entry.type == "directory" then
        table.insert(child_dirs, path)
      end
    end
  end

  table.sort(child_dirs)
  local child_files = {}
  for _, child_dir in ipairs(child_dirs) do
    local child_file_limit = MAX_CANDIDATES_PER_SCAN + 1 - #direct_files
    if child_file_limit <= 0 then
      break
    end
    append_child_files(child_files, child_dir, clients, child_file_limit)
  end

  local paths = {}
  vim.list_extend(paths, direct_files)
  vim.list_extend(paths, child_files)
  local candidates_truncated = #paths > MAX_CANDIDATES_PER_SCAN
  if candidates_truncated then
    paths[MAX_CANDIDATES_PER_SCAN + 1] = nil
  end
  return paths, current_dir, candidates_truncated
end

local function ignored_paths(directory, paths, callback)
  if #paths == 0 then
    callback({})
    return
  end

  local relative_paths = {}
  local by_relative = {}
  for _, item in ipairs(paths) do
    local relative = vim.fs.relpath(directory, item.path)
    if relative then
      table.insert(relative_paths, relative)
      by_relative[relative] = item.path
    end
  end

  if #relative_paths == 0 then
    callback({})
    return
  end

  local command = { "git", "-C", directory, "check-ignore", "--no-index", "-z", "--stdin" }
  local ok, process = pcall(vim.system, command, {
    stdin = table.concat(relative_paths, "\0") .. "\0",
  }, function(result)
    local ignored = {}
    if result.code == 0 and result.stdout then
      local start = 1
      while true do
        local finish = result.stdout:find("\0", start, true)
        if not finish then
          break
        end
        local relative = result.stdout:sub(start, finish - 1)
        if by_relative[relative] then
          ignored[by_relative[relative]] = true
        end
        start = finish + 1
      end
    end
    callback(ignored)
  end)

  if not ok or not process then
    callback({})
  end
end

M.filter_ignored = ignored_paths

local function close_record(client_id, path, discard_buffer)
  local record = records[client_id][path]
  local client = vim.lsp.get_client_by_id(client_id)
  if client and not client:is_stopped() then
    client.notify("textDocument/didClose", {
      textDocument = { uri = vim.uri_from_fname(path) },
    })
  end
  records[client_id][path] = nil
  if not next(records[client_id]) then
    records[client_id] = nil
  end
  if discard_buffer and record.created_buffer and vim.api.nvim_buf_is_valid(record.bufnr)
    and not vim.api.nvim_buf_is_loaded(record.bufnr)
  then
    vim.api.nvim_buf_delete(record.bufnr, { force = true })
    buffers[path] = nil
  end
end

local function close_synthetic_path(path)
  for client_id, client_records in pairs(records) do
    local record = client_records[path]
    if record then
      close_record(client_id, path)
    end
  end
end

local function open_file(item, expected_generation)
  local path = item.path
  local filetype = item.filetype
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" or stat.size > MAX_FILE_SIZE then
    return
  end

  local lines = vim.fn.readfile(path, "b")
  if not lines then
    return
  end
  local text = table.concat(lines, "\n")
  local existing_bufnr = vim.fn.bufnr(path)
  if existing_bufnr ~= -1 and vim.api.nvim_buf_is_loaded(existing_bufnr) then
    return
  end

  local bufnr = existing_bufnr
  local created_buffer = bufnr == -1
  if created_buffer then
    bufnr = vim.fn.bufadd(path)
    if bufnr == 0 then
      return
    end
    vim.bo[bufnr].buflisted = false
  end
  buffers[path] = { bufnr = bufnr, created = created_buffer }

  for _, client in ipairs(matching_clients(path, filetype)) do
    if expected_generation ~= generation then
      return
    end
    local client_records = records[client.id]
    if not client_records or not client_records[path] then
      local uri = vim.uri_from_fname(path)
      client.notify("textDocument/didOpen", {
        textDocument = {
          uri = uri,
          languageId = filetype,
          version = 0,
          text = text,
        },
      })
      records[client.id] = records[client.id] or {}
      records[client.id][path] = {
        bufnr = bufnr,
        created_buffer = created_buffer,
        scope = item.scope,
      }
    end
  end
end

local function needs_open(item)
  local bufnr = vim.fn.bufnr(item.path)
  if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
    return false
  end
  for _, client in ipairs(item.clients) do
    if not client:is_stopped() and (not records[client.id] or not records[client.id][item.path]) then
      return true
    end
  end
  return false
end

local function scan_paths(bufnr, force)
  local paths, directory, candidates_truncated = M.collect_paths(bufnr)
  if not paths then
    return
  end

  local scan_generation = stop_queue()
  active_oil_buffer = bufnr
  local scope_paths = {}
  for _, item in ipairs(paths) do
    scope_paths[item.path] = true
  end

  if force then
    for client_id, client_records in pairs(records) do
      local to_close = {}
      for path, record in pairs(client_records) do
        if scope_paths[path] or (not candidates_truncated and record.scope == directory) then
          table.insert(to_close, path)
        end
      end
      for _, path in ipairs(to_close) do
        close_record(client_id, path, true)
      end
    end
  end

  ignored_paths(directory, paths, function(ignored)
    vim.schedule(function()
      if scan_generation ~= generation or active_oil_buffer ~= bufnr then
        return
      end
      local queue = {}
      local limited = candidates_truncated
      for _, item in ipairs(paths) do
        if not ignored[item.path] and needs_open(item) then
          if #queue == MAX_FILES_PER_SCAN then
            limited = true
            break
          end
          item.scope = directory
          table.insert(queue, item)
        end
      end

      if limited then
        vim.notify(
          ("Oil diagnostics scan is limited to %d unscanned files in this directory scope"):format(
            MAX_FILES_PER_SCAN
          ),
          vim.log.levels.WARN,
          { title = "Oil diagnostics" }
        )
      end

      local function dispatch()
        if scan_generation ~= generation or active_oil_buffer ~= bufnr then
          return
        end
        local item = table.remove(queue, 1)
        if not item then
          if queue_timer then
            queue_timer:close()
            queue_timer = nil
          end
          return
        end
        open_file(item, scan_generation)
        if #queue > 0 then
          queue_timer = queue_timer or vim.uv.new_timer()
          queue_timer:start(OPEN_INTERVAL_MS, 0, vim.schedule_wrap(dispatch))
        elseif queue_timer then
          queue_timer:close()
          queue_timer = nil
        end
      end

      dispatch()
    end)
  end)
end

function M.refresh(_, refresh_action)
  refreshing = true
  local ok, err = pcall(refresh_action)
  if not ok then
    refreshing = false
    error(err)
  end
  vim.schedule(function()
    refreshing = false
    local current_buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(current_buf) and require("oil").get_current_dir(current_buf) then
      scan_paths(current_buf, true)
    end
  end)
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true
  local group = vim.api.nvim_create_augroup("oil-lsp-diagnostics-scan", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OilEnter",
    callback = function(event)
      local bufnr = event.data and event.data.buf or event.buf
      if not bufnr or bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
      end
      if not refreshing then
        scan_paths(bufnr, false)
      end
    end,
    desc = "Scan the current Oil directory for diagnostics",
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    callback = function(event)
      if event.buf == active_oil_buffer then
        active_oil_buffer = nil
        stop_queue()
      end
    end,
    desc = "Cancel pending Oil diagnostics scans when leaving Oil",
  })

  vim.api.nvim_create_autocmd("BufReadPre", {
    group = group,
    callback = function(event)
      local name = vim.api.nvim_buf_get_name(event.buf)
      if name ~= "" then
        local path = normalize(name)
        close_synthetic_path(path)
        local buffer = buffers[path]
        if buffer and buffer.created and vim.api.nvim_buf_is_valid(buffer.bufnr) then
          vim.bo[buffer.bufnr].buflisted = true
        end
        buffers[path] = nil
      end
    end,
    desc = "Transfer synthetic diagnostic documents to real file buffers",
  })
end

return M
