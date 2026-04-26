local M = {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        bash = { "shfmt" },
        c = { "clang_format" },
        go = { "goimports", "gofmt" },
        html = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        lua = { "stylua" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        shell = { "shfmt" },
        sql = { "sqlfluff" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        yaml = { "yamlfmt" },
        ["*"] = { "trim_whitespace" },
      },
      formatters = {
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
        shfmt = {
          prepend_args = { "-i", "2" },
        },
        sqlfluff = {
          prepend_args = { "fix", "--force", "--dialect=postgres", "-" },
        },
      },
      -- If this is set, Conform will run the formatter on save.
      -- It will pass the table to conform.format().
      -- This can also be a function that returns the table.
      format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 500,
      },
      -- Set the log level. Use `:ConformInfo` to see the location of the log file.
      log_level = vim.log.levels.ERROR,
      -- Conform will notify you when a formatter errors
      notify_on_error = true,
      -- Conform will notify you when no formatters are available for the buffer
      notify_no_formatters = true,
    })

  end,
}
return M
