local M = {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
          require("copilot").setup({
            suggestion = { enabled = false },
            panel = { enabled = true },
          })
        end,
        lazy = false,
      },

      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup({
            method = "getCompletionsCycling", -- This enables multiple suggestions
            max_item_count = 3, -- Show up to 3 suggestions at once
            event = { "InsertEnter", "LspAttach" },
            fix_pairs = true,
          })
        end,
        lazy = false,
      },
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {},
    config = function()
      require("CopilotChat").setup({
        model = "claude-3.7-sonnet",
        mappings = {
          reset = {
            normal = "<A-l>",
            insert = "<A-l>",
          },
        },
      })
    end,
  },
}
return M
