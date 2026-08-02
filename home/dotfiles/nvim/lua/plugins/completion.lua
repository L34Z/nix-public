-- Completion — nvim-cmp fed by LSP + buffer + path, with LuaSnip snippets.
return {
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			{
				"L3MON4D3/LuaSnip",
				dependencies = { "rafamadriz/friendly-snippets" },
				build = "make install_jsregexp",
			},
			"saadparwaiz1/cmp_luasnip",
			"windwp/nvim-autopairs",
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load() -- friendly-snippets
			require("nvim-autopairs").setup({}) -- auto-pair brackets while typing

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
				}),
			})

			-- Nim only: on accepting a proc/func/method/template, expand a snippet
			-- of its parameter names so you can Tab through them (e.g.
			-- initHealth(${1:hp})). This is the client-side fill-in nimsuggest
			-- won't do itself: it reads the signature the server already sends.
			-- Falls back to an empty () when there are no params or the signature
			-- can't be parsed. Gated to nim buffers so it never touches other
			-- languages, whose servers already send their own snippet completions.
			local CALLABLE = { [2] = true, [3] = true, [4] = true, [15] = true } -- Method, Function, Constructor, Snippet (Nim templates/macros)

			local function param_names(sig)
				if type(sig) ~= "string" then
					return nil
				end
				local open = sig:find("%(")
				if not open then
					return nil
				end
				local depth, close = 0, nil
				for i = open, #sig do
					local ch = sig:sub(i, i)
					if ch == "(" then
						depth = depth + 1
					elseif ch == ")" then
						depth = depth - 1
						if depth == 0 then
							close = i
							break
						end
					end
				end
				if not close then
					return nil
				end
				local inner = sig:sub(open + 1, close - 1)
				if inner:match("^%s*$") then
					return {} -- callable, but zero params
				end
				local parts, buf, d = {}, "", 0
				for i = 1, #inner do
					local ch = inner:sub(i, i)
					if ch == "(" or ch == "[" then
						d = d + 1
					elseif ch == ")" or ch == "]" then
						d = d - 1
					end
					if ch == "," and d == 0 then
						parts[#parts + 1] = buf
						buf = ""
					else
						buf = buf .. ch
					end
				end
				parts[#parts + 1] = buf
				local names, has_block = {}, false
				for _, p in ipairs(parts) do
					-- A `body: untyped` param takes a trailing block, not a value
					-- inside the parens — flag it so we can open a : block instead.
					if p:match(":%s*untyped%s*$") then
						has_block = true
					else
						names[#names + 1] = p:match("^%s*([%w_]+)%s*:") or ("p" .. (#names + 1))
					end
				end
				return names, has_block
			end

			cmp.event:on("confirm_done", function(evt)
				if vim.bo.filetype ~= "nim" then
					return
				end
				local entry = evt and evt.entry
				if not entry then
					return
				end
				local item = entry:get_completion_item()
				if not item or not CALLABLE[item.kind] then
					return
				end
				if item.insertTextFormat == 2 then
					return -- server already sent a snippet
				end
				local col = vim.api.nvim_win_get_cursor(0)[2]
				local line = vim.api.nvim_get_current_line()
				if line:sub(col + 1, col + 1) == "(" then
					return -- a call is already open here
				end

				local sig = item.detail
				if not sig and type(item.labelDetails) == "table" then
					sig = item.labelDetails.detail
				end
				local names, has_block = param_names(sig)
				-- Method-call syntax (store.add(...)) already supplies the first
				-- parameter as the receiver, so drop it from the placeholders.
				local word = entry:get_word()
				if names and #names > 0 and col - #word >= 1 and line:sub(col - #word, col - #word) == "." then
					table.remove(names, 1)
				end
				local ph = {}
				for i, n in ipairs(names or {}) do
					ph[i] = "${" .. i .. ":" .. n .. "}"
				end
				local body
				if has_block then
					-- Template with a block arg: close the call and open a : block
					-- with the cursor indented on the next line.
					local args = #ph > 0 and ("(" .. table.concat(ph, ", ") .. ")") or ""
					body = args .. ":\n\t$0"
				elseif #ph > 0 then
					body = "(" .. table.concat(ph, ", ") .. ")"
				else
					body = "($0)"
				end
				luasnip.lsp_expand(body)
			end)
		end,
	},
}
