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
            suggestion = {
              enabled = true,
              auto_trigger = true,
              hide_during_completion = false,
              debounce = 75,
              keymap = {
                accept = "[]",
                accept_word = false,
                accept_line = false,
                next = "]]",
                prev = "[[",
                dismiss = "][",
              },
            },
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
