local telescope = require("config.telescope")

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "ff", telescope.find_files, desc = "Find project files" },
      { "fr", telescope.buffers, desc = "Find open buffers" },
      { "fs", telescope.workspace_symbols, desc = "Find project symbols" },
    },
    opts = {},
  },
}
