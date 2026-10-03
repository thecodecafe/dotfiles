local M = {}

local supported_extensions = {
  json = true,
  yaml = true,
  yml = true,
}

local function absolute_path(path, cwd)
  if not path or path == "" then
    return nil
  end

  if path:sub(1, 1) ~= "/" then
    path = vim.fs.joinpath(cwd or vim.uv.cwd(), path)
  end

  return vim.fs.normalize(path)
end

function M.is_openapi_file(filename)
  if type(filename) ~= "string" or filename == "" then
    return false
  end

  local basename = vim.fs.basename(filename):lower()
  local stem, extension = basename:match("^(.*)%.([^.]*)$")
  if not stem or not supported_extensions[extension] then
    return false
  end

  return stem:find("openapi", 1, true) ~= nil or stem:find("swagger", 1, true) ~= nil
end

local function project_context(filename)
  local config_root = vim.fs.root(filename, { "redocly.yaml", "redocly.yml" })
  if config_root then
    return config_root, true
  end

  local root = vim.fs.root(filename, ".git") or vim.fs.dirname(filename)
  return root, false
end

function M.parse_output(output, bufnr, linter_cwd)
  local decoded_ok, report = pcall(vim.json.decode, output)
  if not decoded_ok or type(report) ~= "table" or type(report.problems) ~= "table" then
    vim.notify_once("Redocly did not return a valid JSON lint report.", vim.log.levels.WARN)
    return {}
  end

  local buffer_path = absolute_path(vim.api.nvim_buf_get_name(bufnr), linter_cwd)
  local diagnostics = {}
  local severity_map = {
    error = vim.diagnostic.severity.ERROR,
    warn = vim.diagnostic.severity.WARN,
    warning = vim.diagnostic.severity.WARN,
    info = vim.diagnostic.severity.INFO,
  }

  for _, problem in ipairs(report.problems) do
    for _, location in ipairs(problem.location or {}) do
      local source_path = location.source and absolute_path(location.source.ref, linter_cwd)
      local start = location.start

      if start and type(start.line) == "number" and type(start.col) == "number"
        and (not source_path or not buffer_path or source_path == buffer_path)
      then
        local finish = location["end"] or start
        diagnostics[#diagnostics + 1] = {
          lnum = start.line - 1,
          col = start.col - 1,
          end_lnum = (finish.line or start.line) - 1,
          end_col = (finish.col or start.col) - 1,
          severity = severity_map[problem.severity] or vim.diagnostic.severity.WARN,
          message = problem.message or "OpenAPI lint issue",
          source = "redocly",
          code = problem.ruleId,
        }
      end
    end
  end

  return diagnostics
end

function M.setup()
  local lint = require("lint")
  lint.linters.redocly = {
    cmd = "redocly",
    args = { "lint", "--format=json", "--extends=minimal" },
    stdin = false,
    append_fname = true,
    ignore_exitcode = true,
    parser = M.parse_output,
  }

  local group = vim.api.nvim_create_augroup("nvim-openapi-lint", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    callback = function(event)
      local filename = vim.api.nvim_buf_get_name(event.buf)
      if not M.is_openapi_file(filename) then
        return
      end

      if vim.fn.executable("redocly") ~= 1 then
        vim.notify_once(
          "OpenAPI linting requires Redocly CLI. Install it with: npm install --global @redocly/cli",
          vim.log.levels.WARN
        )
        return
      end

      local root, has_config = project_context(filename)
      vim.api.nvim_buf_call(event.buf, function()
        lint.try_lint("redocly", {
          cwd = root,
          wrap_linter = function(linter)
            local configured = vim.deepcopy(linter)
            configured.args = { "lint", "--format=json" }
            if not has_config then
              configured.args[#configured.args + 1] = "--extends=minimal"
            end
            return configured
          end,
        })
      end)
    end,
    desc = "Lint OpenAPI specs with Redocly after saving",
  })
end

return M
