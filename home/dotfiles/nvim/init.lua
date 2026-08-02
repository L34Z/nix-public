-- Neovim / Neovide config — hand-rolled, live-editable.
--
-- This dir is symlinked out-of-store to ~/nixos/home/dotfiles/nvim (see
-- home/z.nix), so edits here take effect on the next launch with no rebuild.
-- Plugins are managed by lazy.nvim (outside Nix, under ~/.local/share/nvim);
-- LSP servers / formatters / debug adapters come from Nix (home/devtools.nix).
--
-- TIP: launch Neovide from inside a devkit `dev` shell so the compiler is on
-- PATH too — that's what gives rust-analyzer/clangd their full feature set.

-- Leader must be set before lazy.nvim loads (keymaps hang off it).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("core.options")
require("core.keymaps")
require("core.neovide")

-- ── Bootstrap lazy.nvim ────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git", "clone", "--filter=blob:none", "--branch=stable",
		"https://github.com/folke/lazy.nvim.git", lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Load every spec under lua/plugins/. Colorscheme is applied inside
-- lua/plugins/theme.lua once the theme plugins are ready.
require("lazy").setup("plugins", {
	change_detection = { notify = false },
	-- Bump the git clone/fetch timeout (default 120s) — slow networks were
	-- timing out on the initial install.
	git = { timeout = 300 },
})
