local M = {}

M.formatters = {
  go = "gopls",
  json = "jsonls",
  lua = "lua_ls",
  yaml = "yamlls",
}

function M.format_buffer(bufnr)
  local filetype = vim.bo[bufnr].filetype
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
