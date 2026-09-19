local M = {
	active = "kanagawa",
	colorschemes = {
		gruvbox = "gruvbox",
		kanagawa = "kanagawa-dragon",
		["rose-pine"] = "rose-pine-main",
		catppuccin = "catppuccin-mocha",
	},
}

function M.apply(name)
	local selected = name or M.active
	local colorscheme = M.colorschemes[selected]
	if not colorscheme then
		local available = table.concat(vim.tbl_keys(M.colorschemes), ", ")
		error(("Unknown theme '%s'. Choose one of: %s"):format(selected, available))
	end

	vim.o.background = "dark"
	if selected == "catppuccin" then
		require("catppuccin").setup({
			flavour = "mocha",
			background = { dark = "mocha", light = "latte" },
		})
	end

	vim.cmd.colorscheme(colorscheme)
end

return M
