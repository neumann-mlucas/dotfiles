require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "bashls",
    "dockerls",
    "gopls",
    "html",
    "jsonls",
    "lua_ls",
    "pyright",
    "sqlls",
    "vimls",
  },
})

-- server-specific overrides (applied before automatic_enable)
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim", "Snacks" } },
    },
  },
})

vim.diagnostic.config({
  virtual_text = {
    current_line = true,
  },
  virtual_lines = false,
})

-- ]d/[d to jump to the next/previous diagnostic, regardless of severity
-- ]e/[e to jump to the next/previous error
vim.keymap.set("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next Error" })
vim.keymap.set("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev Error" })

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    -- gD/gd to jump to declaration/definition
    -- gh to show hover information
    -- gri/grr/grn/gra to show implementation/references/definition/diagnostics
    -- <space>ca to show available code actions
    -- <space>rn to rename symbol under cursor
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gh", vim.lsp.buf.hover, opts)
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)
  end,
})
