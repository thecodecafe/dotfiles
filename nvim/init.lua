vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.formatting").setup()
require("config.lazy")
