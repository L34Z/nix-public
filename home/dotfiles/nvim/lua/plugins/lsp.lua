-- LSP — one server per devkit language. Servers come from Nix
-- (home/devtools.nix), NOT mason (mason binaries don't run on NixOS).
--
-- nvim 0.12 native API: nvim-lspconfig ships the server configs as lsp/*.lua
-- on the runtimepath; we set shared capabilities via vim.lsp.config("*", …)
-- and turn servers on with vim.lsp.enable{…}. No lspconfig.setup() framework.
return {
	{
		"neovim/nvim-lspconfig",
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			-- Advertise nvim-cmp's completion capabilities to every server.
			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				require("cmp_nvim_lsp").default_capabilities()
			)
			vim.lsp.config("*", { capabilities = capabilities })

			-- Server config names as shipped by nvim-lspconfig (lsp/<name>.lua).
			-- nim_langserver == the `nimlangserver` binary we install.
			vim.lsp.enable({
				"clangd", -- C23
				"rust_analyzer", -- Rust
				"ols", -- Odin
				"nim_langserver", -- Nim
				"pyright", -- Python (types)
				"ruff", -- Python (lint; format handled by conform)
			})

			-- Buffer-local keymaps, set only once a server actually attaches.
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local map = function(keys, fn, desc)
						vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
					end
					map("gd", vim.lsp.buf.definition, "Goto definition")
					map("gD", vim.lsp.buf.declaration, "Goto declaration")
					map("gi", vim.lsp.buf.implementation, "Goto implementation")
					map("gr", vim.lsp.buf.references, "References")
					map("K", vim.lsp.buf.hover, "Hover docs")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
				end,
			})

			-- Nicer diagnostic presentation.
			vim.diagnostic.config({
				virtual_text = true,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})
		end,
	},
}
