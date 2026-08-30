local M = {}

local definition_method = "textDocument/definition"

local function location_uri(location)
  return location.targetUri or location.uri
end

local function location_range(location)
  return location.targetSelectionRange or location.range or location.targetRange
end

local function position_is_in_range(position, range)
  local starts_before = position.line > range.start.line
    or (position.line == range.start.line and position.character >= range.start.character)
  local ends_after = position.line < range["end"].line
    or (position.line == range["end"].line and position.character < range["end"].character)

  if range.start.line == range["end"].line and range.start.character == range["end"].character then
    ends_after = position.line == range.start.line and position.character == range.start.character
  end

  return starts_before and ends_after
end

local function context_is_current(context)
  return vim.api.nvim_win_is_valid(context.winid)
    and vim.api.nvim_get_current_win() == context.winid
    and vim.api.nvim_get_current_buf() == context.bufnr
    and vim.deep_equal(vim.api.nvim_win_get_cursor(context.winid), context.cursor)
end

local function cursor_position(context, offset_encoding)
  local line = vim.api.nvim_buf_get_lines(context.bufnr, context.cursor[1] - 1, context.cursor[1], false)[1] or ""
  return {
    line = context.cursor[1] - 1,
    character = vim.str_utfindex(line, offset_encoding, context.cursor[2], false),
  }
end

local function is_at_definition(definition, context)
  if location_uri(definition.location) ~= vim.uri_from_bufnr(context.bufnr) then
    return false
  end

  local range = location_range(definition.location)
  if not range then
    return false
  end

  return position_is_in_range(cursor_position(context, definition.client.offset_encoding), range)
end

local function request_definitions(callback)
  local context = {
    bufnr = vim.api.nvim_get_current_buf(),
    winid = vim.api.nvim_get_current_win(),
  }
  context.cursor = vim.api.nvim_win_get_cursor(context.winid)

  local clients = vim.lsp.get_clients({ bufnr = context.bufnr, method = definition_method })
  if vim.tbl_isempty(clients) then
    vim.notify("No attached language server supports definitions", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf_request_all(context.bufnr, definition_method, function(client)
    return vim.lsp.util.make_position_params(context.winid, client.offset_encoding)
  end, function(results)
    if not context_is_current(context) then
      return
    end

    local definitions = {}
    local client_ids = vim.tbl_keys(results)
    table.sort(client_ids)

    for _, client_id in ipairs(client_ids) do
      local response = results[client_id]
      local client = vim.lsp.get_client_by_id(client_id)
      if client and response and not response.err and response.result then
        local locations = vim.islist(response.result) and response.result or { response.result }
        for _, location in ipairs(locations) do
          table.insert(definitions, { location = location, client = client })
        end
      end
    end

    if vim.tbl_isempty(definitions) then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end

    callback(definitions, context)
  end)
end

function M.goto_definition_or_references()
  request_definitions(function(definitions, context)
    local at_definition = vim.iter(definitions):any(function(definition)
      return is_at_definition(definition, context)
    end)

    if at_definition then
      require("config.telescope").references()
      return
    end

    vim.lsp.buf.definition()
  end)
end

function M.preview_definition()
  request_definitions(function(definitions)
    vim.lsp.util.preview_location(definitions[1].location, {
      border = "rounded",
      focusable = true,
    })
  end)
end

return M
