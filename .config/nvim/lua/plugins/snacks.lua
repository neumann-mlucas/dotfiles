local M = {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    animate = { enabled = true },
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    dashboard = { enabled = true },
    debug = { enabled = false },
    dim = { enabled = false },
    explorer = { enabled = true },
    git = { enabled = false },
    gitbrowse = { enabled = false },
    indent = { enabled = true },
    input = { enabled = true },
    lazygit = { enabled = true },
    notifier = { enabled = true, timeout = 5000 },
    picker = { enabled = true },
    quickfile = { enabled = false },
    rename = { enabled = true },
    scope = { enabled = false },
    scratch = { enabled = false },
    scroll = { enabled = true },
    statuscolumn = { enabled = false },
    terminal = { enabled = false },
    toggle = { enabled = true },
    win = { enabled = false },
    words = { enabled = true },
    zen = { enabled = true },
    styles = {
      notification = {
        wo = { wrap = true },
      },
    },
  },
  keys = {
    -- bufdelete / explorer
    {
      "<leader>x",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete Buffer",
    },
    {
      "<leader>e",
      function()
        Snacks.explorer()
      end,
      desc = "File Explorer",
    },

    -- picker: files
    {
      "<leader>ff",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<leader>fb",
      function()
        Snacks.picker.buffers()
      end,
      desc = "Buffers",
    },
    {
      "<leader>fo",
      function()
        Snacks.picker.recent()
      end,
      desc = "Recent Files",
    },

    -- picker: search
    {
      "<leader>fg",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live Grep",
    },
    {
      "<leader>fG",
      function()
        Snacks.picker.lines()
      end,
      desc = "Buffer Lines",
    },
    {
      "<leader>fw",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep Word",
      mode = { "n", "x" },
    },
    {
      "<leader>fT",
      function()
        Snacks.picker.tags()
      end,
      desc = "Tags",
    },

    -- picker: lsp
    {
      "<leader>fs",
      function()
        Snacks.picker.lsp_symbols()
      end,
      desc = "Document Symbols",
    },
    {
      "<leader>ft",
      function()
        Snacks.picker.lsp_workspace_symbols()
      end,
      desc = "Workspace Symbols",
    },
    {
      "<leader>fr",
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "References",
    },
    {
      "<leader>fd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "Definitions",
    },
    {
      "<leader>ic",
      function()
        Snacks.picker.lsp_incoming_calls()
      end,
      desc = "Incoming Calls",
    },
    {
      "<leader>oc",
      function()
        Snacks.picker.lsp_outgoing_calls()
      end,
      desc = "Outgoing Calls",
    },
    {
      "<leader>d",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer Diagnostics",
    },

    -- picker: git
    {
      "<leader>gf",
      function()
        Snacks.picker.git_files()
      end,
      desc = "Git Files",
    },
    {
      "<leader>gs",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
    {
      "<leader>gc",
      function()
        Snacks.picker.git_log()
      end,
      desc = "Git Log",
    },

    -- picker: vim
    {
      "z=",
      function()
        Snacks.picker.spelling()
      end,
      desc = "Spell Suggest",
    },
    {
      "<leader>fk",
      function()
        Snacks.picker.keymaps()
      end,
      desc = "Keymaps",
    },
    {
      "<leader>f/",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume Last Picker",
    },
    {
      "<leader>fu",
      function()
        Snacks.picker.undo()
      end,
      desc = "Undo History",
    },

    -- zen / notifications / lazygit
    {
      "<leader>zz",
      function()
        Snacks.zen()
      end,
      desc = "Toggle Zen Mode",
    },
    {
      "<leader>nn",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification History",
    },
    {
      "<leader>gh",
      function()
        Snacks.lazygit.log_file()
      end,
      desc = "Lazygit Current File History",
    },
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },

    -- words
    {
      "]]",
      function()
        Snacks.words.jump(vim.v.count1)
      end,
      desc = "Next Reference",
      mode = { "n", "t" },
    },
    {
      "[[",
      function()
        Snacks.words.jump(-vim.v.count1)
      end,
      desc = "Prev Reference",
      mode = { "n", "t" },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Create some toggle mappings
        Snacks.toggle.diagnostics():map("<leader>ud")
        Snacks.toggle.dim():map("<leader>uD")
        Snacks.toggle.indent():map("<leader>ug")
        Snacks.toggle.inlay_hints():map("<leader>uh")
        Snacks.toggle.line_number():map("<leader>ul")
        Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
        Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
        Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
      end,
    })
  end,
}

return M
