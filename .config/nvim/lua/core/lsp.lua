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

-- Built-in completion (nvim 0.12+)
vim.opt.completeopt = "menuone,noselect,popup"

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }

    -- enable built-in LSP completion for this buffer
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })

    -- gD/gd to jump to declaration/definition
    -- gh to show hover information
    -- gri/grr/grn/gra built-in (0.11+)
    -- <space>ca to show available code actions
    -- <space>rn to rename symbol under cursor
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gh", vim.lsp.buf.hover, opts)
    vim.keymap.set({ "n", "v" }, "<space>ca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<space>rn", vim.lsp.buf.rename, opts)

    -- completion keymaps: CR to confirm, Tab/S-Tab to navigate
    vim.keymap.set("i", "<CR>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-y>"
      end
      return "<CR>"
    end, { buffer = ev.buf, expr = true })

    vim.keymap.set("i", "<Tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-n>"
      end
      return "<Tab>"
    end, { buffer = ev.buf, expr = true })

    vim.keymap.set("i", "<S-Tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-p>"
      end
      return "<S-Tab>"
    end, { buffer = ev.buf, expr = true })
  end,
})
