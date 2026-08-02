-- Editor baseline. Kept intentionally small; plugin-specific options live with
-- their plugin spec under lua/plugins/.
local o = vim.opt

-- Hybrid relative line numbers: absolute on the cursor line, relative elsewhere.
o.number = true
o.relativenumber = true

o.signcolumn = "yes" -- reserve the gutter so diagnostics don't shift text
o.cursorline = true

-- Indentation — 2 spaces by default; per-language overrides (4 for c/rust/
-- python) are applied by the FileType autocmd below.
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true

-- Search
o.ignorecase = true
o.smartcase = true
o.hlsearch = false
o.incsearch = true

-- Files / undo
o.undofile = true -- persistent undo across sessions
o.swapfile = false
o.clipboard = "unnamedplus" -- use the system clipboard

-- UI / behaviour
o.termguicolors = true
o.mouse = "a"
o.scrolloff = 8
o.updatetime = 250 -- snappier diagnostics / CursorHold
o.timeoutlen = 400
o.splitright = true
o.splitbelow = true
o.wrap = true
o.linebreak = true -- wrap at word boundaries, not mid-word

-- Four-space languages. Two-space stays the default for everything else.
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "rust", "python" },
	callback = function()
		vim.bo.shiftwidth = 4
		vim.bo.tabstop = 4
		vim.bo.softtabstop = 4
	end,
})

-- Nim forbids tabs; force spaces even if a plugin flips expandtab off.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "nim",
	callback = function()
		vim.bo.expandtab = true
	end,
})
