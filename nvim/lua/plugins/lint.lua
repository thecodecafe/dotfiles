return {
  {
    "mfussenegger/nvim-lint",
    ft = { "json", "yaml" },
    config = function()
      require("config.openapi_lint").setup()
    end,
  },
}
