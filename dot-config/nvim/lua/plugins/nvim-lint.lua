local M = {
  "mfussenegger/nvim-lint",
  event = {
    "BufReadPre",
    "BufNewFile",
  },
  config = function()
    local lint = require("lint")
    lint.linters_by_ft = {
      bash = { "shellcheck" },
      dockerfile = { "hadolint" },
      go = { "golangcilint" },
      haskell = { "hlint" },
      markdown = { "markdownlint" },
      python = { "mypy", "ruff" },
      shell = { "shellcheck" },
      sql = { "sqlfluff" },
      typescript = { "deno" },
      typescriptreact = { "deno" },
      yaml = { "yamllint" },
    }

    local sqlfluff = require("lint").linters.sqlfluff
    sqlfluff.args = { "lint", "--format=json", "--dialect=postgres", "-" }
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
        lint.try_lint("typos")
      end,
    })

    vim.keymap.set("n", "<leader>ll", function()
      lint.try_lint()
      lint.try_lint("typos")
    end, { desc = "Trigger linting for current file" })
  end,
}
return M
