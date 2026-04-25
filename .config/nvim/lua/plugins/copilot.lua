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
                accept = "<C-l>",
                accept_word = "<C-j>",
                accept_line = false,
                next = "<M-]>",
                prev = "<M-[>",
                dismiss = "<C-]>",
              },
            },
          })
        end,
        lazy = false,
      },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    opts = {},
    config = function()
      require("CopilotChat").setup({
        auto_fold = true,
        auto_insert_mode = true,
        chat_autocomplete = false,
        diff = "block",
        model = "claude-sonnet-4.5",
        mappings = {
          reset = { normal = "<A-l>", insert = "<A-l>" },
          sticky = {
            "#buffers:listed",
            "#gitdiff",
            "#glob:**/*.py",
            "#glob:**/*.lua",
            "#selection",
          },
        },
      })
    end,
  },
}
return M
