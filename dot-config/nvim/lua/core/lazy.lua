-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "plugins" },
    -- LANGUAGE SERVER UTILS
    { "neovim/nvim-lspconfig", lazy = false },
    { "mason-org/mason.nvim" },
    { "mason-org/mason-lspconfig.nvim" },
    { "WhoIsSethDaniel/mason-tool-installer.nvim" },
    -- MISC / SIMPLE SETUP
    { "rhysd/clever-f.vim" },
    -- COLOR SCHEMES
    { "ellisonleao/gruvbox.nvim", lazy = true },
    { "shaunsingh/nord.nvim", lazy = true },
    { "rebelot/kanagawa.nvim", lazy = false, priority = 1000 },
    -- PERFORMANCE
    {
      "zeioth/garbage-day.nvim",
      dependencies = "neovim/nvim-lspconfig",
      event = "VeryLazy",
      opts = {},
    },
    -- FUN
    {
      "nvzone/typr",
      dependencies = "nvzone/volt",
      opts = {},
      cmd = { "Typr", "TyprStats" },
    },
  },

  -- automatically check for plugin updates
  checker = { enabled = false },
})
