return {
  "stevearc/oil.nvim",
  lazy = false,
  opts = {
    default_file_explorer = true,
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<Esc>"] = "actions.close",
      ["gR"] = "actions.refresh",
    },
  },
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
}
