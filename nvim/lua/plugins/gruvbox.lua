return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    -- Use Gruvbox's softer, lower-contrast palette.
    contrast = "soft",
  },
  config = function(_, opts)
    vim.o.background = "dark"
    require("gruvbox").setup(opts)
    vim.cmd.colorscheme("gruvbox")
  end,
}
