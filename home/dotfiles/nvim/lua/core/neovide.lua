-- Neovide GUI settings. No-ops under terminal nvim (guarded by vim.g.neovide).
if not vim.g.neovide then
	return
end

-- Match the kitty font (home/dotfiles/kitty/kitty.conf). JetBrainsMono Nerd
-- Font is installed system-wide (hosts/nix/configuration.nix).
vim.o.guifont = "JetBrainsMono Nerd Font:h14"

vim.g.neovide_padding_top = 8
vim.g.neovide_padding_bottom = 8
vim.g.neovide_padding_left = 8
vim.g.neovide_padding_right = 8

-- Let the DMS/matugen theme's background show through slightly.
vim.g.neovide_opacity = 0.96
vim.g.neovide_window_blurred = true

-- Cursor feel — subtle, not distracting.
vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_cursor_trail_size = 0.3
vim.g.neovide_scroll_animation_length = 0.2

-- Ctrl +/- / 0 to scale the GUI font on the fly.
local function scale(delta)
	return function()
		vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1.0) + delta
	end
end
vim.keymap.set("n", "<C-=>", scale(0.1), { desc = "Neovide: zoom in" })
vim.keymap.set("n", "<C-->", scale(-0.1), { desc = "Neovide: zoom out" })
vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end, { desc = "Neovide: reset zoom" })
