local M = {}
local navigation = require("config.lsp_navigation")

M.servers = {
  "gopls",
  "lua_ls",
  "ts_ls",
  "cssls",
  "html",
  "somesass_ls",
  "jsonls",
  "yamlls",
}

function M.ensure_installed()
  return vim.tbl_filter(function(server)
    return server ~= "gopls" or vim.fn.executable("go") == 1
  end, M.servers)
end

function M.attach_keymaps(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end

  if client:supports_method("textDocument/rename") then
    vim.keymap.set("n", "<F2>", vim.lsp.buf.rename, {
      buffer = event.buf,
      desc = "Rename symbol",
    })
  end

  if client:supports_method("textDocument/definition") then
    vim.keymap.set("n", "gd", navigation.goto_definition_or_references, {
      buffer = event.buf,
      desc = "Go to definition or find references",
    })
    vim.keymap.set("n", "gh", navigation.preview_definition, {
      buffer = event.buf,
      desc = "Preview definition",
    })
  end
end

function M.setup_keymaps()
  local group = vim.api.nvim_create_augroup("nvim-lsp-keymaps", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = M.attach_keymaps,
    desc = "Set supported LSP keymaps",
  })
end

function M.setup(mason_lspconfig_opts)
  M.setup_keymaps()

  vim.lsp.config("*", {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
  })

  local schemastore = require("schemastore")

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
      },
    },
  })

  -- Some Sass provides richer SCSS support, so avoid attaching cssls twice.
  vim.lsp.config("cssls", {
    filetypes = { "css" },
  })

  vim.lsp.config("somesass_ls", {
    filetypes = { "scss" },
  })

  vim.lsp.config("jsonls", {
    settings = {
      json = {
        format = { enable = true },
        schemas = schemastore.json.schemas(),
        validate = { enable = true },
      },
    },
  })

  vim.lsp.config("yamlls", {
    settings = {
      redhat = { telemetry = { enabled = false } },
      yaml = {
        schemaStore = {
          enable = false,
          url = "",
        },
        schemas = schemastore.yaml.schemas(),
        validate = true,
        completion = true,
        format = { enable = true },
        hover = true,
      },
    },
  })

  require("mason-lspconfig").setup(mason_lspconfig_opts)
end

return M
