-- bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

plugins = {
	-- CORE PLUGINS
	"folke/lazy.nvim",
	{
		"neovim/nvim-lspconfig",
		event = { "BufRead", "BufNewFile" },
	},
	{ "williamboman/mason.nvim" },
	{ "williamboman/mason-lspconfig.nvim" },
	{
		"nvim-treesitter/nvim-treesitter",
		event = "VeryLazy",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"HiPhish/rainbow-delimiters.nvim",
			"windwp/nvim-ts-autotag",
		},
	},
	{
		"hrsh7th/nvim-cmp",
		event = "VeryLazy",
		dependencies = {
			"f3fora/cmp-spell",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-path",
			"petertriho/cmp-git",
			"saadparwaiz1/cmp_luasnip",
			"L3MON4D3/LuaSnip",
			"rafamadriz/friendly-snippets",
		},
	},
	{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	-- DAP
	"mfussenegger/nvim-dap",
	"mfussenegger/nvim-dap-python",
	{ "rcarriga/nvim-dap-ui", dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" } },
	-- OTHER PLUGINS
	"RRethy/vim-illuminate",
	"akinsho/toggleterm.nvim",
	"chentoast/marks.nvim",
	"karb94/neoscroll.nvim",
	"lewis6991/gitsigns.nvim",
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
	"machakann/vim-sandwich",
	"numToStr/Comment.nvim",
	"preservim/tagbar",
	"rhysd/clever-f.vim",
	"shortcuts/no-neck-pain.nvim",
	"windwp/nvim-autopairs",
	-- LANGUAGE SPECIFIC
	{ "kdheepak/JuliaFormatter.vim" },
	{ "olexsmir/gopher.nvim", dependencies = { "nvim-lua/plenary.nvim", "nvim-treesitter/nvim-treesitter" } },
	-- COLORSHEMES
	{ "ellisonleao/gruvbox.nvim", lazy = false },
	{ "shaunsingh/nord.nvim", lazy = false },
	-- COSMETIC
	{ "akinsho/bufferline.nvim", dependencies = { "kyazdani42/nvim-web-devicons" } },
	{ "folke/noice.nvim", dependencies = { "MunifTanjim/nui.nvim" } },
	{ "goolord/alpha-nvim", dependencies = { "kyazdani42/nvim-web-devicons" } },
	{ "nvim-lualine/lualine.nvim", dependencies = { "kyazdani42/nvim-web-devicons" } },
	{ "nvimtools/none-ls.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
	-- TEST
	{
		"zeioth/garbage-day.nvim",
		dependencies = "neovim/nvim-lspconfig",
		event = "VeryLazy",
		opts = {
			-- your options here
		},
	},
}

require("lazy").setup(plugins, opts)
