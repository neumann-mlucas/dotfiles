local M = {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>f", group = "find/picker" },
      { "<leader>g", group = "git" },
      { "<leader>h", group = "git hunks" },
      { "<leader>u", group = "toggle" },
      { "<leader>w", group = "dictionary" },
      { "<leader>S", desc = "Pipe through bash" },
      { "<leader>b", desc = "Breakpoint" },
      { "<leader>B", desc = "Run to cursor" },
      { "<leader>d", desc = "Buffer diagnostics" },
      { "<leader>e", desc = "File explorer" },
      { "<leader>x", desc = "Delete buffer" },
      { "<leader>zz", desc = "Zen mode" },
      { "<leader>nn", desc = "Notifications" },
      { "]", group = "next" },
      { "[", group = "prev" },
      { "g", group = "goto/misc" },
      { "gr", group = "LSP (built-in)" },
      { "z", group = "folds/spelling" },
    },
  },
}
return M
