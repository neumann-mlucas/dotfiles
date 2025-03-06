local M = {
  "fredrikaverpil/godoc.nvim",
  version = "*",
  dependencies = {
    { "nvim-telescope/telescope.nvim" }, -- optional
    { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "go" } } },
  },
  opts = {
    picker = {
      type = "telescope", -- native (vim.ui.select) | telescope | snacks | mini | fzf_lua
    },
  },
  build = "go install github.com/lotusirous/gostdsym/stdsym@latest", -- optional
  cmd = { "GoDoc" },
}
return M
