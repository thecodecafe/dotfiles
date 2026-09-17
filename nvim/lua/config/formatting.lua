local M = {}

M.formatters = {
  go = "gopls",
  json = "jsonls",
  lua = "lua_ls",
  yaml = "yamlls",
}

M.sql_formatter = "pg_format"

local function format_sql_buffer(bufnr)
  if vim.fn.executable(M.sql_formatter) == 0 then
    vim.notify("SQL formatting requires pgFormatter. Install it with: brew install pgformatter", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local input = table.concat(lines, "\n")
  if vim.bo[bufnr].endofline then
    input = input .. "\n"
  end

  local ok, process = pcall(vim.system, { M.sql_formatter, "-" }, {
    stdin = input,
    text = true,
  })
  if not ok then
    vim.notify(string.format("SQL formatting failed: %s", process), vim.log.levels.WARN)
    return
  end

  local result_ok, result = pcall(function()
    return process:wait()
  end)
  if not result_ok or result.code ~= 0 then
    local error_message = result_ok and (result.stderr ~= "" and result.stderr or "pg_format exited unsuccessfully") or result
    vim.notify(string.format("SQL formatting failed: %s", error_message), vim.log.levels.WARN)
    return
  end

  local formatted = vim.split(result.stdout or "", "\n", { plain = true })
  if formatted[#formatted] == "" then
    table.remove(formatted)
  end
  if #formatted == 0 then
    formatted = { "" }
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
end

local function scan_dbml_line(line, state)
  local depth_delta = 0
  local first_token
  local index = 1

  while index <= #line do
    local character = line:sub(index, index)
    local next_characters = line:sub(index, index + 1)
    local triple_quote = line:sub(index, index + 2)

    if state.block_comment then
      if next_characters == "*/" then
        state.block_comment = false
        index = index + 2
      else
        index = index + 1
      end
    elseif state.quote == "'''" then
      if triple_quote == "'''" then
        state.quote = nil
        index = index + 3
      else
        index = index + 1
      end
    elseif state.quote then
      if character == "\\" then
        index = index + 2
      elseif character == state.quote then
        state.quote = nil
        index = index + 1
      else
        index = index + 1
      end
    elseif next_characters == "//" then
      break
    elseif next_characters == "/*" then
      state.block_comment = true
      index = index + 2
    elseif triple_quote == "'''" then
      state.quote = "'''"
      index = index + 3
    elseif character == "'" or character == '"' or character == "`" then
      state.quote = character
      index = index + 1
    elseif character == "{" or character == "}" then
      first_token = first_token or character
      depth_delta = depth_delta + (character == "{" and 1 or -1)
      index = index + 1
    else
      if not character:match("%s") then
        first_token = first_token or "text"
      end
      index = index + 1
    end
  end

  return depth_delta, first_token
end

function M.format_dbml(lines)
  local state = {}
  local depth = 0
  local formatted = {}

  for _, line in ipairs(lines) do
    local depth_delta, first_token = scan_dbml_line(line, state)
    local indentation_depth = depth

    if first_token == "}" then
      indentation_depth = depth - 1
    end

    if indentation_depth < 0 then
      return nil, "unmatched closing brace"
    end

    if line:match("%S") then
      formatted[#formatted + 1] = string.rep("  ", indentation_depth) .. line:gsub("^%s*", "")
    else
      formatted[#formatted + 1] = line
    end

    depth = depth + depth_delta
    if depth < 0 then
      return nil, "unmatched closing brace"
    end
  end

  if depth ~= 0 or state.block_comment or state.quote then
    return nil, "unclosed DBML structure"
  end

  return formatted
end

local function format_dbml_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local formatted, error_message = M.format_dbml(lines)
  if not formatted then
    vim.notify(string.format("DBML formatting skipped: %s", error_message), vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
end

function M.format_buffer(bufnr)
  local filetype = vim.bo[bufnr].filetype
  if filetype == "dbml" then
    format_dbml_buffer(bufnr)
    return
  end

  if filetype == "sql" then
    format_sql_buffer(bufnr)
    return
  end

  local formatter = M.formatters[filetype]
  if not formatter then
    return
  end

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
    method = "textDocument/formatting",
  })
  local has_formatter = vim.iter(clients):any(function(client)
    return client.name == formatter
  end)

  if not has_formatter then
    vim.notify(string.format("No %s formatter is attached", formatter), vim.log.levels.WARN)
    return
  end

  local ok, error_message = pcall(vim.lsp.buf.format, {
    bufnr = bufnr,
    async = false,
    timeout_ms = 2000,
    filter = function(client)
      return client.name == formatter
    end,
  })

  if not ok then
    vim.notify(string.format("Formatting failed: %s", error_message), vim.log.levels.WARN)
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("nvim-format-on-save", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = function(event)
      M.format_buffer(event.buf)
    end,
    desc = "Format selected filetypes before saving",
  })
end

return M
