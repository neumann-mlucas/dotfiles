local M = {
  "nvim-treesitter/nvim-treesitter",
  event = "VeryLazy",
  build = ":TSUpdate",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "windwp/nvim-ts-autotag",
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- One of "all", "maintained" (parsers with maintainers), or a list of languages
      ensure_installed = {
        "bash",
        "c",
        "clojure",
        "go",
        "haskell",
        "html",
        "javascript",
        "json",
        "julia",
        "lua",
        "python",
        "vim",
        "markdown",
        "markdown_inline",
        "regex",
      },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      incremental_selection = { enable = false },
      indent = { enable = true },
      -- See: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
      textobjects = {
        select = {
          enable = true,
          -- Automatically jump forward to textobj, similar to targets.vim
          lookahead = true,
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["il"] = "@loop.inner",
          },
          selection_modes = {
            ["@function.outer"] = "V",
            ["@function.inner"] = "V",
            ["@class.outer"] = "V",
            ["@class.inner"] = "V",
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]f"] = "@function.outer",
            ["]C"] = "@class.outer",
          },
          goto_next_end = {
            ["]F"] = "@function.outer",
            -- ["]C"] = "@class.outer",
          },
          goto_previous_start = {
            ["[f"] = "@function.outer",
            ["[C"] = "@class.outer",
          },
          goto_previous_end = {
            ["[F"] = "@function.outer",
            -- ["[C"] = "@class.outer",
          },
        },
      },
    })

    require("nvim-ts-autotag").setup()
  end,
}
return M
