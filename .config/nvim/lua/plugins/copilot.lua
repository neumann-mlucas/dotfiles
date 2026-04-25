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
                accept = "<C-y>",
                accept_word = false,
                accept_line = false,
                next = "<C-n>",
                prev = "<C-p>",
                dismiss = "<C-e>",
              },
            },
          })
        end,
        lazy = false,
      },
      { "nvim-lua/plenary.nvim" },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown" },
        },
        ft = { "markdown" },
      },
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
