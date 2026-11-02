local parsers = {
  "bash",
  "c",
  "clojure",
  "diff",
  "dockerfile",
  "gitcommit",
  "gitignore",
  "go",
  "haskell",
  "html",
  "javascript",
  "json",
  "julia",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "regex",
  "sql",
  "toml",
  "vim",
  "yaml",
}

local M = {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- main branch: setup() only takes install_dir; install() is a no-op for present parsers
    require("nvim-treesitter").install(parsers)

    require("nvim-treesitter-textobjects").setup({
      select = {
        lookahead = true,
        selection_modes = {
          ["@function.outer"] = "V",
          ["@function.inner"] = "V",
          ["@class.outer"] = "V",
          ["@class.inner"] = "V",
        },
      },
      move = { set_jumps = true },
    })

    require("nvim-ts-autotag").setup()

    vim.api.nvim_create_autocmd("FileType", {
      pattern = parsers,
      callback = function(ev)
        pcall(vim.treesitter.start, ev.buf)
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    local select = require("nvim-treesitter-textobjects.select")
    local move = require("nvim-treesitter-textobjects.move")
    local map = function(modes, lhs, fn)
      vim.keymap.set(modes, lhs, fn)
    end

    map({ "x", "o" }, "af", function()
      select.select_textobject("@function.outer", "textobjects")
    end)
    map({ "x", "o" }, "if", function()
      select.select_textobject("@function.inner", "textobjects")
    end)
    map({ "x", "o" }, "ac", function()
      select.select_textobject("@class.outer", "textobjects")
    end)
    map({ "x", "o" }, "ic", function()
      select.select_textobject("@class.inner", "textobjects")
    end)
    map({ "x", "o" }, "il", function()
      select.select_textobject("@loop.inner", "textobjects")
    end)

    map({ "n", "x", "o" }, "]f", function()
      move.goto_next_start("@function.outer", "textobjects")
    end)
    map({ "n", "x", "o" }, "]C", function()
      move.goto_next_start("@class.outer", "textobjects")
    end)
    map({ "n", "x", "o" }, "]F", function()
      move.goto_next_end("@function.outer", "textobjects")
    end)
    map({ "n", "x", "o" }, "[f", function()
      move.goto_previous_start("@function.outer", "textobjects")
    end)
    map({ "n", "x", "o" }, "[C", function()
      move.goto_previous_start("@class.outer", "textobjects")
    end)
    map({ "n", "x", "o" }, "[F", function()
      move.goto_previous_end("@function.outer", "textobjects")
    end)
  end,
}
return M
