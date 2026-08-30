return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    opts = {
      messages = {
        view_search = false,
      },
      presets = {
        bottom_search = false,
        command_palette = true,
      },
    },
  },
}
