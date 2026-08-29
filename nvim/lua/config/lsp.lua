local M = {}

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

function M.setup(mason_lspconfig_opts)
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
