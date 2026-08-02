-- Colorscheme — tracks the DankMaterialShell desktop theme.
--
-- DMS's matugen writes ~/.config/nvim/colors/dms.lua (this dir, live-symlinked)
-- on every wallpaper/mode change. That generated colorscheme requires the
-- AvengeMedia/base46 plugin and installs fs-watchers so nvim re-themes
-- instantly. Enable it once with: matugenTemplateNeovim=true in
-- ~/.config/DankMaterialShell/settings.json (or the DMS settings UI), then
-- re-apply a wallpaper to generate colors/dms.lua.
--
-- catppuccin is the instant fallback for before that first generation (or if
-- base46 misbehaves): `:colorscheme catppuccin`.
return {
	-- base46 must be present and loaded before `colorscheme dms` is sourced.
	{
		"AvengeMedia/base46",
		lazy = false,
		priority = 1000,
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 999,
		opts = { flavour = "mocha" },
	},

	-- Apply the theme once plugins are ready. Prefer the live DMS theme; fall
	-- back to catppuccin if colors/dms.lua hasn't been generated yet.
	{
		"AvengeMedia/base46",
		config = function()
			if not pcall(vim.cmd.colorscheme, "dms") then
				vim.cmd.colorscheme("catppuccin")
			end
		end,
	},
}
