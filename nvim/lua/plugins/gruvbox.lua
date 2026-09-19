return {
	"ellisonleao/gruvbox.nvim",
	lazy = false,
	priority = 1000,
	dependencies = {
		"rebelot/kanagawa.nvim",
		{ "rose-pine/neovim", name = "rose-pine" },
		{ "catppuccin/nvim", name = "catppuccin" },
		"ydkulks/cursor-dark.nvim",
		"tiesen243/vercel.nvim",
	},
	opts = {
		-- Use Gruvbox's softer, lower-contrast palette.
		contrast = "hard",
	},
	config = function(_, opts)
		vim.o.background = "dark"
		require("gruvbox").setup(opts)
		require("config.theme").apply()
	end,
}
