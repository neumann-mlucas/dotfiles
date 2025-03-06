local M = {
  "ray-x/go.nvim",
  dependencies = {
    "ray-x/guihua.lua",
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("go").setup({
      remap_commands = { GoDoc = false },
    })
  end,
  event = { "CmdlineEnter" },
  ft = { "go", "gomod" },
  build = ':lua require("go.install").update_all_sync()',
}
return M

-- CMD LIST
-- :GoAddTest
-- :GoTagAdd :GoTagRm
-- :GoImpl       -> e.g :GoImpl r Read io.Reader
-- :GoCmt
-- :GoIfErr
-- :GoDoc
-- :GoFillStruct -> foo := Foo{} -> Foo{a: []string{}, b: []string{}}
-- :GoFillSwitch -> write all possible cases
-- :GoFixPlurals -> fn foo(a int, b int) -> foo(a, b int)
