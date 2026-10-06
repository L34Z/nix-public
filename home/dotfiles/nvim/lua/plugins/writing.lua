-- Distraction-free prose writing. Toggle with <leader>z.
-- zen-mode centres the column + hides the gutter and drives twilight (dimming);
-- scrolloff=999 in on_open keeps the current line vertically centred.
return {
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        keys = {
            { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle writing mode" },
        },
        dependencies = { "folke/twilight.nvim" },
        opts = {
            window = {
                width = 80, -- prose column width; gutters fill the rest
                options = {
                    number = false,
                    relativenumber = false,
                    signcolumn = "no",
                    cursorline = false,
                },
            },
            plugins = {
                twilight = { enabled = true }, -- dim non-focused text
                gitsigns = { enabled = false },
                options = { enabled = true, ruler = false, showcmd = false },
            },
            on_open = function()
                vim.o.scrolloff = 999 -- keep current line vertically centred
            end,
            on_close = function()
                vim.o.scrolloff = 8 -- restore baseline (options.lua:34)
            end,
        },
    },
    {
        "folke/twilight.nvim",
        opts = {
            dimming = { alpha = 0.4 }, -- how much unfocused text fades
            context = 10, -- lines of focus around the cursor
        },
    },
}
